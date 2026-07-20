import SwiftUI

/// S17 対戦詳細（ターンごとの記録）
struct HistoryDetailView: View {
    let record: GameRecord

    var body: some View {
        NavScreen(title: record.date.formatted(date: .numeric, time: .omitted) + " の対戦") {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    summaryCard
                    Text("ターンの記録")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                    ForEach(record.turns) { turn in
                        turnCard(turn)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let winner = record.winnerName {
                Label("優勝: \(winner) \(record.totals[winner] ?? 0)点", systemImage: "crown.fill")
                    .font(Theme.font(18))
                    .foregroundStyle(Theme.ink)
            }
            Text("\(record.rounds)ラウンド・\(record.playerNames.count)人（\(record.playerNames.joined(separator: "・"))）")
                .font(Theme.font(12))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
        )
    }

    private func turnCard(_ turn: TurnRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: turn.outcome == "correct" ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(turn.outcome == "correct" ? Theme.success : Theme.error)
                Text("お題「\(turn.topicText)」")
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("回答: \(turn.answererName)")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.inkSecondary)
            }
            ForEach(turn.hints) { hint in
                HStack(spacing: 8) {
                    Text(hint.playerName)
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(width: 64, alignment: .leading)
                    Text(hint.char)
                        .font(Theme.font(18))
                        .foregroundStyle(hint.isDeleted ? Theme.inkDisabled : Theme.ink)
                        .strikethrough(hint.isDeleted)
                    Text(hint.isDeleted ? "削除" : hint.rank.map { "\($0)位" } ?? "")
                        .font(Theme.font(11))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
        )
    }
}
