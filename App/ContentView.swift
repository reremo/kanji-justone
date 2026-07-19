import SwiftUI
import KanjiCore

struct ContentView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        Group {
            switch session.engine.phase {
            case .answererReveal: AnswererRevealView()
            case .topicGate: TopicGateView()
            case .topicReveal: TopicRevealView()
            case .hintHandoff: HintHandoffView()
            case .hintInput: HintInputView()
            case .hintConfirm: HintConfirmView()
            case .answerHandoff: AnswerHandoffView()
            case .answerInput: AnswerInputView()
            case .judge: JudgeView()
            case .ranking: RankingView()
            case .turnResult(let outcome): TurnResultView(outcome: outcome)
            case .roundResult: RoundResultView()
            case .finalResult: FinalResultView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.engine.phase)
    }
}
