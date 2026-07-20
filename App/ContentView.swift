import SwiftUI
import KanjiCore

struct ContentView: View {
    @Environment(GameSession.self) private var session
    @State private var showPause = false

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
        .overlay(alignment: .topTrailing) {
            Button {
                showPause = true
            } label: {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.chalkFaded)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .padding(.top, 6)
        }
        .fullScreenCover(isPresented: $showPause) {
            PauseMenuView()
        }
    }
}
