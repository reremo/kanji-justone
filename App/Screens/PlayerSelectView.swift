import SwiftUI
import KanjiCore

/// S03 プレイヤー選択・登録
struct PlayerSelectView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath
    @State private var newName = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        let count = app.selectedPlayers.count
        NavScreen(title: "だれが遊ぶ？") {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("タップして今回の参加者を選ぶ（3〜8人・おすすめは3〜6人）")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                    ForEach(app.roster) { player in
                        let selected = app.selectedPlayerIDs.contains(player.id)
                        Button {
                            app.toggleSelection(player.id)
                        } label: {
                            CardRow {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(selected ? Theme.success : Theme.inkDisabled)
                                Text(player.name)
                                    .font(Theme.font(18))
                                    .foregroundStyle(Theme.ink)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(selected ? Theme.primary : .clear, lineWidth: 2.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 8) {
                        TextField("新しいプレイヤーの名前", text: $newName)
                            .font(Theme.font(16))
                            .foregroundStyle(Theme.ink)
                            .focused($nameFieldFocused)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                        Button {
                            app.addPlayer(name: newName)
                            newName = ""
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 52, height: 52)
                                .background(Circle().fill(Theme.primary))
                        }
                        .buttonStyle(.plain)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        } actions: {
            ChalkButton(title: count >= 3 ? "\(count)人で遊ぶ — 設定へ" : "3人以上えらんでください",
                        enabled: (3...8).contains(count)) {
                path.append(HomeRoute.setup)
            }
        }
    }
}
