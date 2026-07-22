import SwiftUI

/// S07-A お題公開・回答者チェックゲート
struct TopicGateView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        HandoffGateView(
            icon: "eye.slash",
            headline: "\(session.engine.answerer.name)は 見てはダメ",
            buttonTitle: "お題公開へ"
        ) {
            session.update { $0.confirmAnswererNotLooking() }
        }
    }
}
