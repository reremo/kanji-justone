import SwiftUI

@main
struct KanjiJustOneApp: App {
    @State private var session = GameSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(session)
                // 秘匿情報の表示中にAppスイッチャーへ内容が写らないようにする
                if scenePhase != .active && isSecretPhase {
                    Theme.boardDark.ignoresSafeArea()
                }
            }
        }
    }

    private var isSecretPhase: Bool {
        switch session.engine.phase {
        case .topicReveal, .hintInput, .hintConfirm, .judge: true
        default: false
        }
    }
}
