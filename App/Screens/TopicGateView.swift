import SwiftUI

/// S07-A お題公開・回答者チェックゲート
struct TopicGateView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        HandoffGateView(
            phaseLabel: "お題を見る",
            lead: "回答者以外の みんなで見ます",
            headline: "\(session.engine.answerer.name)さんは\n見ていませんか？",
            note: "回答者が画面を見ていなければOKを押してください",
            buttonTitle: "OK — お題を表示"
        ) {
            session.update { $0.confirmAnswererNotLooking() }
        }
    }
}
