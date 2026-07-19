# 技術選定レポート: 漢字ジャストワン

> 作成日: 2026-07-20
> 前提: 既存スキル = React/TypeScript・Swift/SwiftUI ／ 予算 = 月額¥1,000以下（Apple年会費別）／ 期間 = 1ヶ月でMVP ／ iOS専用（Android展開なし）

## 推奨技術スタック（サマリー）

| レイヤー | 推奨技術 | 選定理由（一言) |
|---------|---------|----------------|
| UI | SwiftUI（iOS 17+、要所で SpriteKit / UIViewRepresentable 併用） | iOS専用でRNの利点が消滅。haptics・演出・IME制御・アクセシビリティはネイティブが明確に有利 |
| 状態管理 | `@Observable`（Observation）＋ enum 状態機械・純粋 reducer | ゲーム進行は有限状態機械そのもの。TCAは1ヶ月MVPには過剰 |
| ドメインロジック | 純粋関数・値型のみ（I/O非依存） | 重複削除・採点・順位付けを単体テストで固める |
| データベース | SwiftData（端末ローカル） | `@Query`でSwiftUI直結・学習コスト最小。統計が複雑化したらGRDBへ移行可 |
| 組み込みお題 | バンドル同梱の読み取り専用JSON（DBにコピーしない） | シード/マイグレーション不要。更新はアプリ更新に同梱 |
| バックエンド | **なし**（完全ローカル） | v1はオンライン機能ゼロ。BaaSは使い道がなくコストと複雑性のみ |
| IAP | StoreKit 2（非消費型「全解除」＋復元） | async/awaitで簡潔。JWSローカル検証でサーバー不要 |
| 広告 | AdMob ＋ Google UMP SDK（同意管理） | 無料・情報豊富。UMPがGDPR同意とATTを一元管理 |
| クラッシュ/分析 | Firebase Crashlytics ＋ Firebase Analytics | AdMobとGoogle系依存を共有し衝突回避。無制限無料 |
| CI/CD | 初期はローカルArchive→手動、安定後 Xcode Cloud（無料25h/月） | GitHub ActionsのmacOSは10倍課金でiOSビルドに不向き |
| 配布 | TestFlight 内部テスト（審査不要・100人） | 1人開発＋友人テストに最適。外部テストは後段 |

## コスト試算

| フェーズ | 月額概算 | 主なコスト |
|---------|---------|-----------|
| 初期（開発〜リリース直後） | ¥0 | サーバー・SaaSすべて無料枠。LLMお題生成は制作時のみ（全体で¥300〜1,000） |
| 成長期（MAU数千） | ¥0 | ローカル完結のためユーザー数がコストに影響しない |
| （別枠）Apple Developer Program | ¥1,082/月相当 | ¥12,980/年。iOS配信に不可避な唯一の固定費 |

- 一時費用: LLMお題生成 ¥300〜1,000、アイコン素材 ¥0〜5,000、効果音 ¥0（効果音ラボ/DOVA等の商用可無料音源）
- 収益参考: 買い切り¥600はSmall Business Program（手数料15%）申請で手取り約¥510。年会費回収は月2〜3件のIAPまたはインタースティシャル月2,200impで到達

## 学習コスト見積もり

- 既存スキルで対応可能: SwiftUIの画面構築全般、TypeScript製のお題変換スクリプト
- 新規学習が必要:
  - SwiftData: 4〜8h
  - StoreKit 2: 4〜6h
  - AdMob＋UMP＋ATT/プライバシーマニフェスト: 6〜8h
  - ルビ描画（CoreText）・グリッドD&D・CoreHaptics・SpriteKitパーティクル: 各0.5〜1日
- **合計追加学習時間: 約25〜40h**（1ヶ月MVPに収まる）

## アーキテクチャ

```
┌────────────── iOS App（SwiftUI, iOS 17+）──────────────┐
│ View層: 各フェーズ画面・演出（haptics/紙吹雪/効果音）      │
│    ↓ 購読(@Observable)      ↑ イベント                  │
│ GameSession（単一ストア・GamePhase状態機械）              │
│    ↓                                                    │
│ Domain（純粋関数のみ: 遷移・重複削除・採点・順位付け）     │
│    ↓                                                    │
│ SwiftData（Player/Topic/Match/Turn/HintSubmission）      │
│ 静的アセット: 組み込みお題JSON（バンドル同梱）            │
│ 外部SDK: StoreKit 2 ／ AdMob＋UMP ／ Crashlytics         │
└─────── バックエンドなし・ネットワーク不要 → 月額¥0 ───────┘
```

- ゲーム進行: `GamePhase`（enum + associated values）を純粋関数 `next(state, event)` で遷移。スキップ・ギブアップ・手動削除もイベントとして流す
- **対戦ログは追記型（append-only）で1文字単位の生ログを保存**（`HintSubmission`: 誰が・どのお題に・どの漢字・生存/自動削除/手動削除・順位）。集計値に潰さない。`schemaVersion`＋JSONエクスポートを用意し、v2のAI分析に備える

## UI実装の要点（SwiftUI）

| 要件 | 実装方針 |
|------|---------|
| ふりがな（ルビ） | CoreText の `CTRubyAnnotation`（UIViewRepresentable）。簡易には漢字上にかな小文字を重ねる自作View |
| 漢字のみ受付 | `markedTextRange` でIME変換中を除外し、確定文字をCJK統合漢字ブロックで判定 |
| 秘匿ロック | 完全不透明オーバーレイ＋`scenePhase`でAppスイッチャーのスナップショット隠し |
| 並べ替え（採点） | List `.onMove`（グリッド形式なら DragGesture＋matchedGeometryEffect 自作） |
| 演出 | PhaseAnimator（ドラムロール/pulse）・KeyframeAnimator・`.contentTransition(.numericText())`（スコア桁送り）・SpriteKit `SKEmitterNode`（紙吹雪） |
| タイマー | TimelineView ＋ `.monospacedDigit()` |
| Reduce Motion | `accessibilityReduceMotion` で全演出をフェードに差し替え |

## 代替案と比較

| 案 | スタック | 学習コスト | 月額 | 向いているケース |
|---|---------|-----------|------|----------------|
| **推奨案** | SwiftUI + SwiftData + StoreKit 2 + AdMob | 低（+25〜40h） | ¥0 | iOS専用・演出重視・1ヶ月MVP（本件） |
| 代替案A | React Native/Expo + Reanimated/Skia | 中（ライブラリ選定・EAS設定） | ¥0〜（EAS Build有料化リスク） | 将来のAndroid展開が現実的な場合 |
| 代替案B | SwiftUI + GRDB(SQLite) | 中 | ¥0 | 統計クエリが複雑化・SQL集計が必要になった場合の移行先 |

## 開始ステップ

1. Apple Developer Program 登録（審査に数日かかるため最初に）
2. Xcodeプロジェクト作成（iOS 17+・SwiftUI・SPM）→ ドメイン層（状態機械・重複削除・採点）を純粋関数＋単体テストで先に実装
3. コアループ画面（S06〜S13）を Pencil デザインどおりに実装 → TestFlight 内部テストで実際に4人で遊ぶ
4. SwiftData 永続化・お題JSON同梱（TSスクリプトで生成・検証）
5. StoreKit 2 → UMP＋AdMob → Privacy Manifest / App Privacyラベル（審査ブロッカー）
6. Crashlytics＋最小アナリティクス（セッション/ゲーム完了/購入/広告表示のみ）

> **ひとことアドバイス**: このアプリの価値は「端末を回す体験の滑らかさ」に集中している。サーバー・クロスプラットフォーム・過剰な計測はすべて捨てて正解。ドメインロジック（重複削除と採点）だけは最初にテストで固めると、以降のUI試行錯誤が怖くなくなる。

## 留意事項

- 唯一の固定費は Apple Developer Program（¥12,980/年 ≒ ¥1,082/月）。ランニングSaaS費は全構成で¥0
- 広告はまず「ラウンド間インタースティシャル or バナー1枚・非パーソナライズ」で開始し、ATT/パーソナライズは後から追加可能（UMPを先に入れておく）
- TestFlightビルドは90日で失効する点に注意
- 既存の `.claude/rules/api-ddd-structure.md`（app/api・Next.js前提のルール）は本プロジェクトの構成と合わないため、実装開始時に iOS 向けルールへの差し替えを推奨
