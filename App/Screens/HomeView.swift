import SwiftUI

enum HomeRoute: Hashable {
    case howTo, players, setup, topicList, history, stats, shop, appSettings
    case historyDetail(GameRecord)
    case terms, privacy
}

/// S01 ホーム
struct HomeView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath
    @State private var showResumePrompt = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(Array("漢字力".enumerated()), id: \.offset) { index, char in
                        KanjiTileView(char: char)
                            .rotationEffect(.degrees([-8, 5, -4][index % 3]))
                    }
                }
                Text("漢字の力")
                    .font(Theme.font(36))
                    .foregroundStyle(Theme.chalk)
                Text("漢字の力で ことばを伝えあう 推理パーティ")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkFaded)
            }
            Spacer()
            VStack(spacing: 12) {
                ChalkButton(title: app.suspendedSession != nil ? "ゲームを始める（中断中あり）" : "ゲームを始める") {
                    if app.suspendedSession != nil {
                        showResumePrompt = true
                    } else {
                        path.append(HomeRoute.players)
                    }
                }
                .confirmationDialog("中断中のゲームがあります", isPresented: $showResumePrompt, titleVisibility: .visible) {
                    Button("再開する") {
                        app.resumeGame()
                    }
                    Button("新しく始める（中断中のゲームは破棄）", role: .destructive) {
                        app.discardSuspendedGame()
                        path.append(HomeRoute.players)
                    }
                    Button("キャンセル", role: .cancel) {}
                }
                navRow {
                    navButton("お題一覧", icon: "book") { path.append(HomeRoute.topicList) }
                }
                navRow {
                    navButton("対戦記録", icon: "clock.arrow.circlepath") { path.append(HomeRoute.history) }
                    navButton("ショップ", icon: "cart") { path.append(HomeRoute.shop) }
                }
                navRow {
                    navButton("遊び方", icon: "questionmark.circle") { path.append(HomeRoute.howTo) }
                    navButton("設定", icon: "gearshape") { path.append(HomeRoute.appSettings) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            if !app.purchased && app.ads.ready {
                BannerAdView()
                    .frame(height: 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.board.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func navRow(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 12) { content() }
    }

    private func navButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(Theme.font(15))
                .foregroundStyle(Theme.chalk)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5))
        }
        .buttonStyle(.pressable)
    }
}
