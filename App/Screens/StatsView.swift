import SwiftUI

/// S18 個人成績（対戦記録から算出）
struct StatsView: View {
    @Environment(AppState.self) private var app
    @State private var selectedName: String?

    private var allNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for record in app.records {
            for name in record.playerNames where !seen.contains(name) {
                seen.insert(name)
                names.append(name)
            }
        }
        return names
    }

    var body: some View {
        NavScreen(title: "個人成績") {
            if allNames.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.ghostIcon)
                    Text("まだ成績がありません。まずは1ゲーム遊ぼう！")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.chalkFaded)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let name = selectedName ?? allNames[0]
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allNames, id: \.self) { candidate in
                                    Button {
                                        selectedName = candidate
                                    } label: {
                                        Text(candidate)
                                            .font(Theme.font(14))
                                            .foregroundStyle(candidate == name ? Theme.ink : Theme.chalk)
                                            .padding(.vertical, 8).padding(.horizontal, 16)
                                            .background {
                                                if candidate == name {
                                                    Capsule().fill(Theme.primary)
                                                } else {
                                                    Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        statGrid(for: name)
                        Text("お題ごとの記録")
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.chalkFaded)
                        topicHistory(for: name)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder
    private func statGrid(for name: String) -> some View {
        let games = app.records.filter { $0.playerNames.contains(name) }
        let hints = games.flatMap(\.turns).flatMap(\.hints).filter { $0.playerName == name }
        let survived = hints.filter { !$0.isDeleted }.count
        let topHints = games.flatMap(\.turns).filter { turn in
            turn.hints.contains { $0.playerName == name && $0.rank == 1 }
        }.count
        let answered = games.flatMap(\.turns).filter { $0.answererName == name && $0.outcome == "correct" }.count
        let rate = hints.isEmpty ? 0 : Int((Double(survived) / Double(hints.count) * 100).rounded())

        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statTile(value: "\(games.count)", label: "遊んだ回数")
                statTile(value: "\(rate)%", label: "ヒント生存率")
            }
            HStack(spacing: 12) {
                statTile(value: "\(topHints)回", label: "1位ヒント")
                statTile(value: "\(answered)回", label: "正解した数")
            }
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.font(12))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private func topicHistory(for name: String) -> some View {
        let entries: [(TurnRecord, [HintRecord])] = app.records.flatMap(\.turns).compactMap { turn in
            let mine = turn.hints.filter { $0.playerName == name }
            return mine.isEmpty ? nil : (turn, mine)
        }
        if entries.isEmpty {
            Text("ヒントを出した記録がまだありません")
                .font(Theme.font(13))
                .foregroundStyle(Theme.chalkFaded)
        }
        ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
            CardRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("お題「\(entry.0.topicText)」")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.ink)
                    if let best = entry.1.compactMap(\.rank).min(), best == 1 {
                        Text("1位ヒント！")
                            .font(Theme.font(11))
                            .foregroundStyle(Theme.primaryDark)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(entry.1) { hint in
                        KanjiTileView(char: Character(hint.char), size: 40, deleted: hint.isDeleted)
                    }
                }
            }
        }
    }
}
