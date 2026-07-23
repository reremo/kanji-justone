import SwiftUI

/// S08-A ヒント入力・本人確認（端末を回す）
struct HintHandoffView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        let name = session.engine.currentHintGiver?.name ?? ""
        HandoffGateView(
            icon: "hand.raised.fill",
            lead: "\(name)がヒントを入力してください",
            headline: "\(name)ですか？",
            buttonTitle: "はい、\(name)です"
        ) {
            session.update { $0.confirmHintPerson() }
        }
    }
}
