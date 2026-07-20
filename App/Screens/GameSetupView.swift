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
                    roundsRow
                    charsRow
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

    /// プラスボタンの状態
    private enum PlusState { case enabled, premium, disabled }

    // ラウンド数（無料は上限2で+が🔒プレミア、上限10で+グレー）
    @ViewBuilder
    private var roundsRow: some View {
        let atFreeLimit = !app.purchased && app.rounds >= AppState.freeMaxRounds
        let atCap = app.rounds >= AppState.maxRoundsCap
        let plusState: PlusState = atCap ? .disabled : (atFreeLimit ? .premium : .enabled)
        stepperCard(label: "ラウンド数", value: "\(app.rounds)",
                    minusEnabled: app.rounds > 1, plusState: plusState) {
            app.rounds = max(1, app.rounds - 1)
        } plus: {
            switch plusState {
            case .enabled: app.rounds += 1
            case .premium: path.append(HomeRoute.shop)
            case .disabled: break
            }
        }
    }

    // ヒント文字数（無料は人数で固定・変更不可で🔒、有料は1〜3自由）
    @ViewBuilder
    private var charsRow: some View {
        if app.purchased {
            let atMax = app.charsPerPlayer >= 5
            stepperCard(label: "一人の文字数", value: "\(app.charsPerPlayer)",
                        minusEnabled: app.charsPerPlayer > 1, plusState: atMax ? .disabled : .enabled) {
                app.charsPerPlayer = max(1, app.charsPerPlayer - 1)
            } plus: {
                if !atMax { app.charsPerPlayer += 1 }
            }
        } else {
            // 無料: 人数で自動決定。値のみ表示し、＋−の代わりに🔒でショップ誘導
            Button {
                path.append(HomeRoute.shop)
            } label: {
                CardRow {
                    Text("一人の文字数")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.ink)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.primaryDark)
                    Spacer()
                    Text("\(app.effectiveCharsPerPlayer)文字")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("（\(app.selectedPlayers.count)人）")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .buttonStyle(.pressable)
        }
    }

    @ViewBuilder
    private func stepperCard(label: String, value: String, minusEnabled: Bool, plusState: PlusState,
                             minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        CardRow {
            Text(label)
                .font(Theme.font(15))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button(action: minus) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 26))
                    .foregroundStyle(minusEnabled ? Theme.inkSecondary : Theme.inkDisabled)
            }
            .buttonStyle(.pressable)
            .disabled(!minusEnabled)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 28)
            Button(action: plus) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 26))
                        .foregroundStyle(plusState == .disabled ? Theme.inkDisabled : Theme.primaryDark)
                    if plusState == .premium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.ink)
                            .padding(2)
                            .background(Circle().fill(Theme.primary))
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .buttonStyle(.pressable)
            .disabled(plusState == .disabled)
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
