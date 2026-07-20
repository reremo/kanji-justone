import SwiftUI
import KanjiCore

/// S21 お題一覧（通常/自作タブ・難易度タブ・自作の管理）
struct TopicListView: View {
    @Environment(AppState.self) private var app
    @State private var customTab = false
    @State private var difficulty: Difficulty = .easy
    @State private var newTopic = ""
    @State private var newFurigana = ""

    var body: some View {
        NavScreen(title: "お題一覧") {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    tabRow
                    if customTab {
                        customList
                    } else {
                        difficultyRow
                        builtinList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        }
    }

    private var tabRow: some View {
        HStack(spacing: 8) {
            tab("通常お題", selected: !customTab, locked: false) { customTab = false }
            tab("自作お題", selected: customTab, locked: !app.purchased) {
                if app.purchased { customTab = true }
            }
        }
    }

    private var difficultyRow: some View {
        HStack(spacing: 8) {
            tab("やさしい", selected: difficulty == .easy, locked: false, small: true) { difficulty = .easy }
            tab("ふつう", selected: difficulty == .normal, locked: false, small: true) { difficulty = .normal }
            tab("むずかしい", selected: difficulty == .hard, locked: false, small: true) { difficulty = .hard }
        }
    }

    @ViewBuilder
    private var builtinList: some View {
        ForEach(app.availableTopics(for: difficulty)) { topic in
            CardRow {
                Text(topic.text)
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.ink)
                Text(topic.furigana)
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        if !app.purchased, app.lockedTopicCount(for: difficulty) > 0 {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.inkDisabled)
                Text("あと\(app.lockedTopicCount(for: difficulty))問")
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.inkDisabled)
                Spacer()
                Text("買い切りで解除")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.primaryDark)
                    .padding(.vertical, 3).padding(.horizontal, 10)
                    .background(Capsule().fill(Theme.primaryLight))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.tileDeletedBg))
        }
    }

    @ViewBuilder
    private var customList: some View {
        Text("「自作お題専用モード」で出題されるリストです（自由に登録OK）")
            .font(Theme.font(13))
            .foregroundStyle(Theme.chalkFaded)
            .fixedSize(horizontal: false, vertical: true)
        ForEach(app.customTopics) { topic in
            CardRow {
                Text(topic.text)
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    app.removeCustomTopic(topic.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.error)
                }
                .buttonStyle(.plain)
            }
        }
        VStack(spacing: 8) {
            TextField("新しいお題", text: $newTopic)
            TextField("ふりがな（よみかた）", text: $newFurigana)
        }
        .font(Theme.font(16))
        .foregroundStyle(Theme.ink)
        .textFieldStyle(.plain)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        ChalkButton(title: "＋ お題を追加する", enabled: !newTopic.trimmingCharacters(in: .whitespaces).isEmpty) {
            app.addCustomTopic(text: newTopic, furigana: newFurigana)
            newTopic = ""
            newFurigana = ""
        }
    }

    private func tab(_ title: String, selected: Bool, locked: Bool, small: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                }
                Text(title).font(Theme.font(small ? 13 : 14))
            }
            .foregroundStyle(selected ? Theme.ink : Theme.chalk)
            .frame(maxWidth: .infinity)
            .frame(height: small ? 34 : 38)
            .background {
                if selected {
                    Capsule().fill(Theme.primary)
                } else {
                    Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
