import SwiftUI

@main
struct KanjiJustOneApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(appState)
                // 秘匿情報の表示中にAppスイッチャーへ内容が写らないようにする
                if scenePhase != .active && isSecretPhase {
                    Theme.boardDark.ignoresSafeArea()
                }
            }
        }
    }

    private var isSecretPhase: Bool {
        switch appState.gameSession?.engine.phase {
        case .topicReveal, .hintInput, .hintConfirm, .judge: true
        default: false
        }
    }
}
