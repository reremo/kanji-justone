import SwiftUI
import KanjiCore

/// S04 ゲーム設定
struct GameSetupView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath
    @State private var startError: String?

    var body: some View {
        @Bindable var app = app
        NavScreen(title: "ゲーム設定") {
            ScrollView {
                VStack(spacing: 12) {
                    stepperRow(label: "ラウンド数", value: app.rounds, locked: !app.purchased && app.rounds >= AppState.freeMaxRounds) {
                        app.rounds = max(1, app.rounds - 1)
                    } plus: {
                        app.rounds = min(app.maxRounds, app.rounds + 1)
                    }
                    stepperRow(label: "一人の文字数", value: app.charsPerPlayer, locked: !app.purchased) {
                        if app.purchased { app.charsPerPlayer = max(1, app.charsPerPlayer - 1) }
                    } plus: {
                        if app.purchased { app.charsPerPlayer = min(3, app.charsPerPlayer + 1) }
                    }
                    segmentCard(label: "お題") {
                        segment(items: [("通常お題", !app.useCustomTopics, false),
                                        ("自作お題", app.useCustomTopics, !app.purchased)]) { index in
                            if index == 1 {
                                if app.purchased { app.useCustomTopics = true }
                            } else {
                                app.useCustomTopics = false
                            }
                        }
                        if !app.useCustomTopics {
                            Text("難しさ（ラウンドごと）")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.inkSecondary)
                            segment(items: [("やさしい", app.difficulty == .easy, false),
                                            ("ふつう", app.difficulty == .normal, false),
                                            ("むずかしい", app.difficulty == .hard, false)]) { index in
                                app.difficulty = [.easy, .normal, .hard][index]
                            }
                        }
                    }
                    segmentCard(label: "回答者の決め方") {
                        segment(items: [("順番", app.answererMode == .sequential, false),
                                        ("ランダム", app.answererMode == .roundRobin, false),
                                        ("固定", isFixed, false)]) { index in
                            switch index {
                            case 0: app.answererMode = .sequential
                            case 1: app.answererMode = .roundRobin
                            default: app.answererMode = .fixed(app.selectedPlayers.first?.id ?? Player(name: "").id)
                            }
                        }
                        if isFixed {
                            Text("回答者にする人をえらぶ")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.inkSecondary)
                            answererChips
                        }
                    }
                    if let startError {
                        Text(startError)
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.chalkWarn)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        } actions: {
            ChalkButton(title: "ゲームスタート！") {
                do {
                    try app.startGame()
                } catch {
                    startError = "ゲームを開始できませんでした（\(error)）"
                }
            }
        }
    }

    private var isFixed: Bool {
        if case .fixed = app.answererMode { return true }
        return false
    }

    private var fixedAnswererID: Player.ID? {
        if case .fixed(let id) = app.answererMode { return id }
        return nil
    }

    /// 固定モードで回答者にする人を参加者から選ぶチップ
    @ViewBuilder
    private var answererChips: some View {
        let columns = [GridItem(.adaptive(minimum: 88), spacing: 8, alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(app.selectedPlayers) { player in
                let selected = fixedAnswererID == player.id
                Button {
                    app.answererMode = .fixed(player.id)
                } label: {
                    Text(player.name)
                        .font(Theme.font(15))
                        .foregroundStyle(selected ? Theme.ink : Theme.inkSecondary)
                        .lineLimit(1)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(selected ? Theme.primary : Theme.tileDeletedBg)
                        )
                }
                .buttonStyle(.pressable)
            }
        }
    }

    @ViewBuilder
    private func stepperRow(label: String, value: Int, locked: Bool, minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        CardRow {
            Text(label)
                .font(Theme.font(15))
                .foregroundStyle(Theme.ink)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Button(action: minus) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .buttonStyle(.pressable)
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 28)
            Button(action: plus) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.primaryDark)
            }
            .buttonStyle(.pressable)
        }
    }

    @ViewBuilder
    private func segmentCard(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(Theme.font(15))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private func segment(items: [(String, Bool, Bool)], onTap: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    onTap(index)
                } label: {
                    HStack(spacing: 4) {
                        if item.2 {
                            Image(systemName: "lock.fill").font(.system(size: 11))
                        }
                        Text(item.0).font(Theme.font(14))
                    }
                    .foregroundStyle(item.1 ? Theme.ink : Theme.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Capsule().fill(item.1 ? Theme.primary : Theme.tileDeletedBg))
                }
                .buttonStyle(.pressable)
            }
        }
    }
}
