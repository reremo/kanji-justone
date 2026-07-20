import SwiftUI

/// ホームのナビゲーションと進行中ゲームの切り替え
struct RootView: View {
    @Environment(AppState.self) private var app
    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                HomeView(path: $path)
                    .navigationDestination(for: HomeRoute.self) { route in
                        destination(for: route)
                    }
            }
            if let session = app.gameSession {
                ContentView()
                    .environment(session)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.gameSession == nil)
        .onChange(of: app.gameSession == nil) { _, isHome in
            if isHome {
                path = NavigationPath()
            }
        }
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .howTo: HowToView()
        case .players: PlayerSelectView(path: $path)
        case .setup: GameSetupView(path: $path)
        case .topicList: TopicListView()
        case .history: HistoryView(path: $path)
        case .historyDetail(let record): HistoryDetailView(record: record)
        case .stats: StatsView()
        case .shop: ShopView()
        case .appSettings: AppSettingsView(path: $path)
        case .terms: LegalTextView(title: "利用規約", content: LegalText.termsOfService)
        case .privacy: LegalTextView(title: "プライバシーポリシー", content: LegalText.privacyPolicy)
        }
    }
}
