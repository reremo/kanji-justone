import SwiftUI
import KanjiCore

/// S03 プレイヤー選択・登録（デザイン案B: 名簿風リスト・チェックは右）
struct PlayerSelectView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath
    @State private var editing = false
    @State private var renameTarget: Player?
    @State private var renameText = ""
    @State private var newName = ""
    @State private var adding = false
    @State private var scrollTarget: Player.ID?
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        let count = app.selectedPlayers.count
        NavScreen(title: "だれが遊ぶ？") {
            VStack(alignment: .leading, spacing: 8) {
                if !app.roster.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            Haptics.light()
                            editing.toggle()
                        } label: {
                            Text(editing ? "完了" : "編集")
                                .font(Theme.font(15))
                                .foregroundStyle(Theme.primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressable)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)
                }
                ScrollViewReader { proxy in
                    List {
                        ForEach(app.roster) { player in
                            playerRow(player)
                                .id(player.id)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        }
                        // システムのドラッグハンドル（カード外の緑地に出て見えない）を使わず、
                        // カード全体を長押しして並び替える
                        .onMove { from, to in
                            app.movePlayers(fromOffsets: from, toOffset: to)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onChange(of: scrollTarget) { _, target in
                        guard let target else { return }
                        withAnimation { proxy.scrollTo(target, anchor: .bottom) }
                    }
                }
            }
            .padding(.top, 12)
        } actions: {
            // ＋を押して初めて入力欄が現れ、1人追加すると入力欄は+ボタンに戻る。
            // 何も追加せずキーボードを閉じても（他をタップ）+ボタンに戻る。
            if adding {
                HStack(spacing: 8) {
                    TextField("新しいプレイヤーの名前", text: $newName)
                        .font(Theme.font(16))
                        .foregroundStyle(Theme.ink)
                        .focused($addFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(addPlayer)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                    Button(action: addPlayer) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(Theme.primary))
                    }
                    .buttonStyle(.pressable)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                Button {
                    Haptics.light()
                    adding = true
                    addFieldFocused = true
                } label: {
                    Label("プレイヤーを追加", systemImage: "plus")
                        .font(Theme.font(16))
                        .foregroundStyle(Theme.chalk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5))
                }
                .buttonStyle(.pressable)
            }
            ChalkButton(title: count >= 3 ? "\(count)人で遊ぶ" : "3人以上えらんでください",
                        enabled: (3...8).contains(count)) {
                path.append(HomeRoute.setup)
            }
        }
        .onChange(of: addFieldFocused) { _, focused in
            // キーボードが閉じたら入力欄を畳んで＋ボタンに戻す
            if !focused {
                adding = false
                newName = ""
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

    private func addPlayer() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.light()
        app.addPlayer(name: trimmed)
        newName = ""
        scrollTarget = app.roster.last?.id  // 追加した行までスクロール
        addFieldFocused = false  // 1人追加したら閉じる（onChangeで入力欄を畳む）
    }

    @ViewBuilder
    private func playerRow(_ player: Player) -> some View {
        let selected = app.selectedPlayerIDs.contains(player.id)
        HStack(spacing: 12) {
            // 左: 編集時は削除、通常時は選択チェック
            if editing {
                Button {
                    Haptics.light()
                    if let index = app.roster.firstIndex(where: { $0.id == player.id }) {
                        withAnimation { app.removePlayers(atOffsets: [index]) }
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.error)
                }
                .buttonStyle(.pressable)
            } else {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(selected ? Theme.success : Theme.tileBorder)
            }
            Text(player.name)
                .font(Theme.font(18))
                .foregroundStyle(Theme.ink)
            Spacer()
            // 右: 編集時は名前変更、通常時は並び替え（長押し）の目印
            if editing {
                Button {
                    renameTarget = player
                    renameText = player.name
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.primaryDark)
                }
                .buttonStyle(.pressable)
            } else {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.inkDisabled)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        // 背景はコンテンツ側にのみ持たせる（listRowBackgroundだと余白まで塗られてカード間が詰まる）
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(selected && !editing ? Theme.primaryLight : Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Theme.tileBorder, lineWidth: 1.5)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !editing else { return }
            Haptics.light()
            app.toggleSelection(player.id)
        }
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
