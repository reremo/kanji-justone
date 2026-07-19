import SwiftUI
import KanjiCore

/// S13 このターンの結果（誰が何を出したか・順位・得点を公開）
struct TurnResultView: View {
    @Environment(GameSession.self) private var session
    let outcome: TurnOutcome

    var body: some View {
        let engine = session.engine
        ChalkScreen(
            background: Theme.boardBright,
            progress: "ラウンド \(engine.roundNumber)/\(engine.config.rounds) ・ \(engine.turnNumber)/\(engine.turnsPerRound)人目",
            title: "このターンの結果",
            titleColor: Theme.chalkPink
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let topic = engine.topic {
                        TopicRow(topic: topic, size: 32)
                            .frame(maxWidth: .infinity)
                    }
                    answererRow(engine: engine)
                    ForEach(engine.hintGivers) { player in
                        hintGiverRow(player: player, engine: engine)
                    }
                    Text(legend)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        } actions: {
            ChalkButton(title: "次へ") {
                session.update { $0.proceedFromTurnResult() }
            }
        }
    }

    private var legend: String {
        switch outcome {
        case .correct: "うすい字＝削除された漢字。削除\(session.engine.deletedCount)つ分のボーナスは回答者に！"
        case .giveUp: "ギブアップ… 全員0点です"
        case .wipeout: "全滅！ ヒントが全部消えたので全員0点です"
        }
    }

    private func outcomeLabel() -> (String, Color) {
        switch outcome {
        case .correct: ("正解！", Theme.success)
        case .giveUp: ("ギブアップ", Theme.inkSecondary)
        case .wipeout: ("全滅…", Theme.error)
        }
    }

    @ViewBuilder
    private func answererRow(engine: GameEngine) -> some View {
        let (label, color) = outcomeLabel()
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.answerer.name)
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.ink)
                Text("回答者")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(width: 88, alignment: .leading)
            Label(label, systemImage: outcome == .correct ? "checkmark.circle.fill" : "xmark.circle")
                .font(Theme.font(15))
                .foregroundStyle(color)
            Spacer()
            Text(points(for: engine.answerer.id, engine: engine))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.success)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
    }

    @ViewBuilder
    private func hintGiverRow(player: Player, engine: GameEngine) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(player.name)
                .font(Theme.font(15))
                .foregroundStyle(Theme.ink)
                .frame(width: 88, alignment: .leading)
            HStack(spacing: 8) {
                ForEach(engine.fates.filter { $0.ownerID == player.id }) { fate in
                    VStack(spacing: 2) {
                        KanjiTileView(char: fate.char, size: 64, deleted: fate.state != .survived)
                        Text(subLabel(for: fate))
                            .font(Theme.font(11))
                            .foregroundStyle(fate.state == .survived ? Theme.primaryDark : Theme.inkSecondary)
                    }
                }
            }
            Spacer()
            Text(points(for: player.id, engine: engine))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.success)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
    }

    private func subLabel(for fate: CharFate) -> String {
        switch fate.state {
        case .survived: fate.rank.map { "\($0)位" } ?? ""
        case .autoDeleted: "自動削除"
        case .manualDeleted: "手動削除"
        }
    }

    private func points(for id: Player.ID, engine: GameEngine) -> String {
        "+\(engine.lastTurnScores[id] ?? 0)点"
    }
}
