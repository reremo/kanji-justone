# 実装計画: iOS基盤とコアゲームループ (plan-core-loop)

> 作成日: 2026-07-20 ／ ブランチ: `feat/ios-project-setup`
> 参照: `docs/requirements/core-requirements.md` / `docs/design/screen-design.md` / `docs/design/ux-guidelines.md` / `docs/architecture/tech-selection.md` / Pencil `kanji-justone-screens.pen`

## スコープ

**やること**
1. ドメイン層を SwiftPM パッケージ `KanjiCore` として実装（純粋関数・値型のみ、`swift test` でCLI検証可能）
2. XcodeGen で iOS 17+ SwiftUI アプリターゲットを生成（実機/シミュレータでビルド可能な骨格）
3. コアループ画面 S06〜S13（受け渡し/確認の状態画面含む）を黒板テイストで実装し、1ターンを通しでプレイ可能にする

**やらないこと（後続機能）**
- SwiftData 永続化（履歴・統計・プレイヤー保存）→ ゲーム開始はデバッグ用固定4人・固定設定で起動
- S01〜S05・S16〜S21 の画面 / IAP / 広告 / 効果音・haptics・紙吹雪演出（フェード等の最小アニメのみ）
- お題コンテンツ100問（開発用ダミー10問のJSONで代替）
- タイマー（`GameConfig.timer` はフィールド予約のみ。UI実装は後続）

**簡易実装で含めるもの**
- S14 ラウンド結果 / S15 最終結果: Pencil デザイン準拠の簡易版（スコアリスト＋次へ/ホームボタンのみ。前回比チップ等の装飾は省略可）— ラウンド走破時に UI の行き先を確保するため

## アーキテクチャ

```mermaid
flowchart TD
    subgraph App[iOSアプリ KanjiJustOne（XcodeGen生成・iOS 17+）]
        V[Views: S06〜S13 各画面\nTheme/共通コンポーネント] -->|イベント送信| GS[GameSession\n@Observable 単一ストア]
        GS -->|購読| V
        GS --> KC
    end
    subgraph KC[SwiftPM: KanjiCore（純粋・I/O非依存）]
        SM[GamePhase 状態機械\nreduce(state, event) -> state]
        DD[dedup: 1文字単位の重複削除]
        SC[scoring: 採点・順位付け・削除ボーナス]
        RO[rotation: 順番/ラウンドロビン/固定]
    end
    TJ[topics-dev.json\nバンドル同梱ダミーお題] --> GS
```

## ドメイン設計（KanjiCore）

### モデル（値型）
- `Player { id, name }`
- `GameConfig { players: [Player](3〜8), rounds, charsPerPlayer(=2), answererMode(.sequential/.roundRobin/.fixed(PlayerID)), timer: Duration? }`
- `Topic { id, text, furigana, difficulty }`
- `HintSubmission { playerID, chars: [Character] }`
- `CharFate { char, ownerID, state: .survived/.autoDeleted/.manualDeleted, rank: Int? }`
- `TurnResult { topic, answererID, outcome: .correct/.giveUp/.wipeout, fates, scores: [PlayerID: Int] }`

### 純粋関数
- `autoDedup(submissions) -> [CharFate]` — 複数プレイヤー間で同じ文字は全滅（同一人物内重複は入力側で禁止済みだが防御的に扱う）
- `applyManualDeletion(fates, char, owner)`
- `score(outcome, fates, ranking, playerCount) -> [PlayerID: Int]`
  - 正解: 回答者 = +P + 削除合計数（自動+手動）。出題者 = 「自分の生存漢字の最高順位」の昇順で並べ、1位 +P、以下1点ずつ減。生存0の出題者は最下位（複数いれば同点で同順位）
  - ギブアップ/全滅: 全員0
- `nextAnswerer(mode, roundIndex, turnIndex, players, seed)` — ラウンドロビンはラウンド毎シャッフルで全員1回ずつ保証。固定モードの1ラウンド = P−1ターン
- `reduce(state: GamePhase, event: GameEvent) -> GamePhase` — 状態機械

### GamePhase（enum, associated values）
```
answererReveal → topicGate（回答者チェック） → topicReveal（スキップ→answererRevealへ戻らずお題再抽選）
→ hintHandoff(i) → hintInput(i) …回答者以外の人数分ループ
→ [autoDedup直後に生存0 → hintConfirmを経ず turnResult(.wipeout) 直行]
→ hintConfirm（手動削除イベント受付。手動削除で生存0 → turnResult(.wipeout)）
→ answerHandoff → answerInput → judge
→ 正解: ranking → turnResult(.correct) ／ 不正解: answerInput へ戻る（回数無制限） ／ ギブアップ: turnResult(.giveUp)
→ 次ターン(answererReveal) / roundResult / finalResult

※ お題スキップは S07 内での再抽選とする（screen-design.md の遷移フローも S07→S07 に更新済み）
※ 生存0の出題者は0点（順位付け対象外）。要件にも追記済み
```

## テストリスト（KanjiCore, XCTest）

**自動重複削除**
- [ ] 2人が同じ文字 → 両方 autoDeleted、他は survived
- [ ] 3人が同じ文字 → 3枚とも削除
- [ ] 重複なし → 全生存
- [ ] 全員の全文字が重複 → 生存0（全滅判定の入力になる）

**採点（P=4, 出題者3人）**
- [ ] 正解・削除0: 回答者+4。出題者は最高順位順に +4/+3/+2
- [ ] 正解・削除3（自動2+手動1）: 回答者 = 4+3 = +7（ボーナスは回答者のみ・自動と手動を合算）
- [ ] 最高順位の比較: 1位1枚だけの出題者 > 2位+3位の2枚を持つ出題者
- [ ] 生存0の出題者は0点（順位付け対象外）。残りの出題者は1位から+P, -1, …
- [ ] ギブアップ: 全員0
- [ ] 全滅: 全員0（outcome = .wipeout）

**回答者ローテーション**
- [ ] sequential: 登録順に1巡
- [ ] roundRobin: 1ラウンド内で重複なく全員1回、ラウンド間で順序が変わり得る（seed固定で決定的にテスト）
- [ ] fixed: 常に同一人物、1ラウンド = P−1ターン

**状態機械**
- [ ] 正常系: answererReveal→…→turnResult まで一巡
- [ ] お題スキップで topicReveal→（お題再抽選して）topicReveal
- [ ] hintInput が人数分（回答者以外）だけ繰り返される
- [ ] hintConfirm で手動削除→生存0 → turnResult(.wipeout) へ直行
- [ ] autoDedup 直後に生存0 → hintConfirm を経ず turnResult(.wipeout) 直行
- [ ] judge(不正解) → answerInput に戻る（状態は維持）
- [ ] judge(giveUp) → ranking をスキップして turnResult
- [ ] 最終ターンの turnResult → roundResult / finalResult 分岐（ラウンド内残ターン・残ラウンドで場合分け）

**入力バリデーション（ドメイン側ガード）**
- [ ] 漢字以外（ひらがな/カタカナ/英数）を拒否。判定は**CJK統合漢字ブロック（拡張含む）のみ許可・「々」「〆」等の記号は不可**で割り切る
- [ ] 同一人物の同字を拒否
- [ ] 設定文字数と不一致を拒否
- [ ] GameConfig: 参加人数 2人以下・9人以上を拒否（3〜8人のみ許可）

## アプリ側 実装対象ファイル

```
project.yml                      … XcodeGen 定義（iOS 17.0+, KanjiCore をローカル依存）
Packages/KanjiCore/              … ドメイン（Sources / Tests）
App/
  KanjiJustOneApp.swift          … エントリポイント（デバッグ: 固定4人でゲーム開始）
  Resources/topics-dev.json      … 開発用お題10問（ふりがな付き）
  Resources/Fonts/KosugiMaru-Regular.ttf
  Theme/Theme.swift              … ux-guidelines のトークン（色HEX・フォント・spacing）
  Components/                    … ChalkScreen(3層ゾーン) / PhaseHeader / ChalkButton(ピル+押し込みエッジ) /
                                    KanjiTileView / GhostSlot / HandoffGate(暗転受け渡し) / TopicRuby(ふりがな)
  Game/GameSession.swift         … @Observable。KanjiCore.reduce を呼びUIへ状態公開
  Screens/                       … S06AnswererReveal / S07TopicGate / S07TopicReveal /
                                    S08HintHandoff / S08HintInput / S09HintConfirm /
                                    S10AnswerHandoff / S10AnswerInput / S11Judge /
                                    S12Ranking / S13TurnResult
```

- 画面仕様は Pencil の各フレームに準拠（文言・レイアウト・3層ゾーン・チョーク配色）
- ふりがな: MVPは「かな小サイズをお題の上に重ねる自作View」で実装（CoreTextルビは後続改善）
- 秘匿: HandoffGate は完全不透明。`scenePhase` のプライバシーオーバーレイは本計画に含める（実装コスト小・価値大）

## 実装手順

1. `brew install xcodegen`（環境に未導入）
2. `Packages/KanjiCore` を作成し、テストリストを**先に**全件書く（Red）→ ドメイン実装（Green）→ `swift test` 全緑
   - Package.swift の `platforms` は **iOS と macOS を併記**（iOSのみ指定すると `swift test` がCLIで動かない）
   - グループ/フラット表示のシャッフルも seed 付き決定的関数としてドメインに置く（テスト可能にする）
3. `project.yml` → `xcodegen` → `xcodebuild -scheme KanjiJustOne -destination 'platform=iOS Simulator,...' build` が通る骨格を確認
   - Kosugi Maru は同梱だけでは有効にならない。project.yml の `info.properties` に **`UIAppFonts`** を登録すること（Apache 2.0 ライセンスファイルも同梱）
4. Theme + 共通コンポーネント → 各画面を S06→S13 の順に実装（GameSession 接続）
5. シミュレータで1ターン通しプレイを確認（正解ルート・ギブアップルート・全滅ルート）
6. docs コミットと分離して実装コミット → PR

## リスクと対応
- **XcodeGen 導入失敗** → 手動で最小 .xcodeproj を Xcode CLIなしで生成できないため、代替は Tuist または手書き pbxproj（最終手段）
- **Kosugi Maru 同梱** → Google Fonts から TTF 取得（Apache 2.0、ライセンスファイル同梱）
- **キーボードでの漢字確定制御** → MVPは「確定文字列を送信時にバリデーション」で開始（markedText 監視は後続改善）
- **ルビの見た目** → 自作View で妥協し、崩れが目立つ場合のみ CoreText へ
