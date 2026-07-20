import SwiftUI
import KanjiCore

/// S03 プレイヤー選択・登録（編集モードで削除・並び替え・名前変更）
struct PlayerSelectView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath
    @State private var newName = ""
    @State private var editing = false
    @State private var renameTarget: Player?
    @State private var renameText = ""

    var body: some View {
        let count = app.selectedPlayers.count
        NavScreen(title: "だれが遊ぶ？") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(editing ? "ドラッグで並び替え・スワイプで削除・タップで名前変更"
                                 : "タップして今回の参加者を選ぶ（3〜8人）")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                    Spacer()
                    if !app.roster.isEmpty {
                        Button(editing ? "完了" : "編集") {
                            Haptics.light()
                            editing.toggle()
                        }
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.primary)
                        .buttonStyle(.plain)
                    }
                }
                List {
                    ForEach(app.roster) { player in
                        playerRow(player)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    }
                    .onMove { from, to in
                        app.movePlayers(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { offsets in
                        app.removePlayers(atOffsets: offsets)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(editing ? .active : .inactive))
                HStack(spacing: 8) {
                    TextField("新しいプレイヤーの名前", text: $newName)
                        .font(Theme.font(16))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                    Button {
                        Haptics.light()
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
            .padding(.bottom, 12)
        } actions: {
            ChalkButton(title: count >= 3 ? "\(count)人で遊ぶ — 設定へ" : "3人以上えらんでください",
                        enabled: (3...8).contains(count)) {
                path.append(HomeRoute.setup)
            }
        }
        .alert("名前を変更", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("名前", text: $renameText)
            Button("変更") {
                if let target = renameTarget {
                    app.renamePlayer(target.id, to: renameText)
                }
                renameTarget = nil
            }
            Button("キャンセル", role: .cancel) { renameTarget = nil }
        }
    }

    @ViewBuilder
    private func playerRow(_ player: Player) -> some View {
        let selected = app.selectedPlayerIDs.contains(player.id)
        Button {
            if editing {
                renameTarget = player
                renameText = player.name
            } else {
                Haptics.light()
                app.toggleSelection(player.id)
            }
        } label: {
            CardRow {
                if !editing {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(selected ? Theme.success : Theme.inkDisabled)
                }
                Text(player.name)
                    .font(Theme.font(18))
                    .foregroundStyle(Theme.ink)
                if editing {
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected && !editing ? Theme.primary : .clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                if let index = app.roster.firstIndex(where: { $0.id == player.id }) {
                    app.removePlayers(atOffsets: [index])
                }
            } label: {
                Label("削除", systemImage: "trash")
            }
            Button {
                renameTarget = player
                renameText = player.name
            } label: {
                Label("名前変更", systemImage: "pencil")
            }
            .tint(Theme.primaryDark)
        }
    }
}
