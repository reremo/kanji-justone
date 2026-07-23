import SwiftUI
import KanjiCore

/// S09 ヒントを確認（回答者以外への受け渡しゲート → 匿名グルーピング・没スタンプでの手動削除）
struct HintConfirmView: View {
    @Environment(GameSession.self) private var session
    @State private var gatePassed = false

    var body: some View {
        if gatePassed {
            confirmScreen
        } else {
            HandoffGateView(
                icon: "person.2.fill",
                lead: "回答者（\(session.engine.answerer.name)）以外で",
                headline: "みんなでヒントを確認",
                buttonTitle: "確認する"
            ) {
                gatePassed = true
            }
        }
    }

    private var confirmScreen: some View {
        let engine = session.engine
        return ChalkScreen(progress: session.progressLine, title: "ヒントを確認") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let topic = engine.topic {
                        TopicRow(topic: topic)
                    }
                    RulesBox()
                    GroupList(groups: engine.confirmDisplayGroups) { fateID in
                        Haptics.light()
                        SoundPlayer.play(.tap)
                        session.update { $0.toggleManualDelete(fateID: fateID) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
        } actions: {
            ChalkButton(title: "確認完了") {
                session.update { $0.finishHintConfirm() }
            }
        }
    }
}

// MARK: - ルール

private struct RulesBox: View {
    private let rules = [
        "お題に含まれる漢字は使わない",
        "お題を和訳しただけの漢字は使わない",
        "漢字を組み合わせて熟語を作らない",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ルール")
                .font(Theme.font(13))
                .foregroundStyle(Theme.primary)
            ForEach(rules, id: \.self) { r in
                HStack(alignment: .top, spacing: 6) {
                    Text("・").font(Theme.font(13)).foregroundStyle(Theme.chalkFaded)
                    Text(r).font(Theme.font(13)).foregroundStyle(Theme.chalkFaded)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 6) {
                SealMark(size: 22)
                Text("違反していたらタップで没に（もう一度で戻す）")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkWarn)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.bandLine, lineWidth: 1.5))
    }
}

// MARK: - グループ一覧

/// 人物単位（匿名）のグループを縦に並べる。各札は枚数に応じて自動縮小し1行に収める。
private struct GroupList: View {
    let groups: [GameEngine.ConfirmGroup]
    let onTapTile: (UUID) -> Void
    @State private var width: CGFloat = 0

    private let gap: CGFloat = 6
    private let boxPad: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(groups) { group in
                let n = group.tiles.count + group.duplicateCount
                let s = tileSize(n)
                groupBox {
                    ForEach(group.tiles) { fate in
                        ConfirmTile(char: fate.char,
                                    stamped: fate.state == .manualDeleted,
                                    size: s)
                            .onTapGesture { onTapTile(fate.id) }
                    }
                    ForEach(0..<group.duplicateCount, id: \.self) { _ in
                        SealedTile(lines: ["重", "複"], size: s, angle: 8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GeometryReader { g in
            Color.clear
                .onAppear { width = g.size.width }
                .onChange(of: g.size.width) { _, w in width = w }
        })
    }

    private func tileSize(_ n: Int) -> CGFloat {
        guard width > 0, n > 0 else { return 60 }
        let inner = width - boxPad * 2
        return min(72, floor((inner - CGFloat(n - 1) * gap) / CGFloat(n)))
    }

    @ViewBuilder
    private func groupBox(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: gap) { content() }
            .padding(boxPad)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.tileBorder, lineWidth: 2))
    }
}

// MARK: - 札

/// 生存／没の札。タップで没トグル。没は透過スタンプで下の字が透ける。
private struct ConfirmTile: View {
    let char: Character
    let stamped: Bool
    let size: CGFloat

    var body: some View {
        KanjiTileView(char: char, size: size)
            .overlay { if stamped { SealStamp(lines: ["没"], size: size) } }
            .animation(.easeOut(duration: 0.15), value: stamped)
    }
}

/// 角印マーク（ルール説明用の小さな印）
private struct SealMark: View {
    var size: CGFloat = 22

    var body: some View {
        Text("没")
            .font(Theme.font(size * 0.6))
            .foregroundStyle(Theme.chalk)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3).fill(Theme.seal))
    }
}
