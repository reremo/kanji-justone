import SwiftUI
import KanjiCore

/// S13 このターンの結果（お題・回答者の得点内訳・誰が何を出したか・役に立った順・点数を全公開）
struct TurnResultView: View {
    @Environment(GameSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let outcome: TurnOutcome
    @State private var celebrated = false
    @State private var shakeX: CGFloat = 0
    @State private var revealShown = false

    var body: some View {
        if !revealShown && session.engine.deletedCount > 0 {
            DeletedRevealView { revealShown = true }
        } else {
            resultScreen
        }
    }

    private var resultScreen: some View {
        let engine = session.engine
        return ChalkScreen(
            background: Theme.boardBright,
            progress: "ラウンド \(engine.roundNumber)/\(engine.config.rounds) ・ \(engine.turnNumber)/\(engine.turnsPerRound)人目",
            title: "このターンの結果"
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    topicBar(engine: engine)
                    answererCard(engine: engine)
                        .padding(.bottom, 4)
                    ForEach(rows(engine: engine)) { row in
                        hintRow(row)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .offset(x: shakeX)
            }
        } actions: {
            ChalkButton(title: "次へ") {
                session.update { $0.proceedFromTurnResult() }
            }
        }
        .task { await playEntranceEffects() }
    }

    // MARK: - お題＋結果バッジ

    @ViewBuilder
    private func topicBar(engine: GameEngine) -> some View {
        let (label, color) = outcomeLabel()
        HStack(spacing: 8) {
            if let topic = engine.topic {
                Text("お題").font(Theme.font(11)).foregroundStyle(Theme.chalkFaded)
                Text(topic.text)
                    .font(Theme.font(18))
                    .foregroundStyle(Theme.chalk)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            Spacer(minLength: 8)
            Text(label)
                .font(Theme.font(13))
                .foregroundStyle(Theme.chalk)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Capsule().fill(color))
                .scaleEffect(celebrated ? 1 : 0.4)
                .opacity(celebrated ? 1 : 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.band))
    }

    // MARK: - 回答者カード（得点内訳）

    /// 回答者カード（王冠なし・金枠で区別。名前と点数は枠の中）
    @ViewBuilder
    private func answererCard(engine: GameEngine) -> some View {
        let total = engine.lastTurnScores[engine.answerer.id] ?? 0
        let base = engine.config.players.count
        let bonus = engine.deletedCount
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("回答者").font(Theme.font(11)).foregroundStyle(Theme.primaryDark)
                Text(engine.answerer.name).font(Theme.font(16)).foregroundStyle(Theme.ink)
            }
            Spacer()
            if outcome == .correct {
                Text("+\(base)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.success)
                if bonus > 0 {
                    Text("+\(bonus)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryDark)
                }
            } else {
                Text("+\(total)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(total > 0 ? Theme.primaryDark : Theme.inkSecondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Theme.primary, lineWidth: 1.5))
        )
    }

    // MARK: - ヒント行（役に立った順・人・点数）

    @ViewBuilder
    private func hintRow(_ row: RowModel) -> some View {
        let fate = row.fate
        let survived = fate.state == .survived
        HStack(spacing: 12) {
            Group {
                if survived {
                    RankBadge(rank: fate.rank)
                } else {
                    SealStamp(lines: fate.state == .manualDeleted ? ["没"] : ["重", "複"], size: 42)
                }
            }
            .frame(width: 42)
            KanjiTileView(char: fate.char, size: 44)
            Text(row.ownerName).font(Theme.font(15)).foregroundStyle(Theme.ink)
            Spacer()
            if let pts = row.points {
                Text("+\(pts)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(pts > 0 ? Theme.success : Theme.inkSecondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(isTop(row) ? Theme.primary : .clear, lineWidth: 2))
        )
    }

    private func isTop(_ row: RowModel) -> Bool {
        row.fate.state == .survived && row.fate.rank == 1
    }

    // MARK: - 行モデル（生存を順位順→削除、点数は人ごと初出のみ）

    private struct RowModel: Identifiable {
        let id: UUID
        let fate: CharFate
        let ownerName: String
        let points: Int?
    }

    private func rows(engine: GameEngine) -> [RowModel] {
        let survivors = engine.fates.filter { $0.state == .survived }.sorted { a, b in
            switch (a.rank, b.rank) {
            case let (ra?, rb?): return ra < rb
            case (_?, nil): return true
            case (nil, _?): return false
            default: return false
            }
        }
        let deleted = engine.fates.filter { $0.state != .survived }
        var seen = Set<Player.ID>()
        return (survivors + deleted).map { fate in
            let name = engine.config.players.first { $0.id == fate.ownerID }?.name ?? "?"
            let pts: Int? = seen.contains(fate.ownerID) ? nil : (engine.lastTurnScores[fate.ownerID] ?? 0)
            seen.insert(fate.ownerID)
            return RowModel(id: fate.id, fate: fate, ownerName: name, points: pts)
        }
    }

    private func outcomeLabel() -> (String, Color) {
        switch outcome {
        case .correct: ("正解！", Theme.success)
        case .giveUp: ("不正解…", Theme.inkSecondary)
        case .wipeout: ("全滅…", Theme.error)
        }
    }

    // MARK: - 演出

    private func playEntranceEffects() async {
        switch outcome {
        case .correct:
            Haptics.success()
            SoundPlayer.play(.correct)
        case .giveUp:
            Haptics.warning()
            SoundPlayer.play(.wrong)
        case .wipeout:
            Haptics.error()
            SoundPlayer.play(.wipeout)
        }
        if reduceMotion {
            celebrated = true
            return
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.5)) { celebrated = true }
        if outcome == .wipeout {
            let swings: [CGFloat] = [-14, 14, -11, 11, -7, 7, -4, 4, -2, 0]
            for (i, x) in swings.enumerated() {
                withAnimation(.linear(duration: 0.05)) { shakeX = x }
                if i == 0 { Haptics.heavy() }
                try? await Task.sleep(for: .milliseconds(56))
            }
        }
    }
}

// MARK: - 部品

/// 順位バッジ（1位＝金・以降は淡い金）
private struct RankBadge: View {
    let rank: Int?
    var body: some View {
        Text(rank.map { "\($0)" } ?? "")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .frame(width: 30, height: 30)
            .background(Circle().fill(rank == 1 ? Theme.primary : Theme.primaryLight))
            .overlay(Circle().strokeBorder(Theme.primaryDark, lineWidth: 1))
    }
}
