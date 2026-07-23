import SwiftUI

/// S10-A お題を当てる・回答者への受け渡し（〇〇さんですか？→はい 構文）
struct AnswerHandoffView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        let name = session.engine.answerer.name
        HandoffGateView(
            icon: "iphone.gen3",
            lead: "回答者の \(name)さんに渡してください",
            headline: "\(name)さんですか？",
            buttonTitle: "はい、\(name)です"
        ) {
            session.update { $0.answererReceived() }
        }
    }
}
