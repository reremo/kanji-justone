import SwiftUI

/// S08-A ヒント入力・本人確認（端末を回す）
struct HintHandoffView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        let name = session.engine.currentHintGiver?.name ?? ""
        HandoffGateView(
            phaseLabel: "ヒントを書く",
            lead: "\(name)さんに 渡してください",
            headline: "\(name)さんですか？",
            note: "本人だけが「はい」を押してください",
            buttonTitle: "はい、\(name)です"
        ) {
            session.update { $0.confirmHintPerson() }
        }
    }
}
