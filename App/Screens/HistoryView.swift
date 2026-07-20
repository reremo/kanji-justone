import SwiftUI

/// S16 対戦記録一覧
struct HistoryView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath

    var body: some View {
        NavScreen(title: "対戦記録") {
            if app.records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.ghostIcon)
                    Text("まだ対戦記録がありません")
                        .font(Theme.font(16))
                        .foregroundStyle(Theme.chalkFaded)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(app.records) { record in
                            Button {
                                path.append(HomeRoute.historyDetail(record))
                            } label: {
                                recordRow(record)
                            }
                            .buttonStyle(.pressable)
                        }
                        Button {
                            path.append(HomeRoute.stats)
                        } label: {
                            Label("個人成績を見る", systemImage: "chart.bar")
                                .font(Theme.font(15))
                                .foregroundStyle(Theme.chalk)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5))
                        }
                        .buttonStyle(.pressable)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
    }

    private func recordRow(_ record: GameRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkDisabled)
            }
            if let winner = record.winnerName {
                Label("\(winner) \(record.totals[winner] ?? 0)点", systemImage: "crown.fill")
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.ink)
            }
            Text(record.playerNames.joined(separator: "・"))
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
}
