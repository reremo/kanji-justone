import SwiftUI
import KanjiCore

/// S10-B お題を当てる（フラット表示＋回答入力）
struct AnswerInputView: View {
    @Environment(GameSession.self) private var session
    @State private var answer = ""
    @FocusState private var focused: Bool

    var body: some View {
        let engine = session.engine
        ChalkScreen(progress: session.progressLine, title: "お題を当てる") {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 0)

                        // お題は何？ を主役に
                        Text("お題は何？")
                            .font(Theme.font(30))
                            .foregroundStyle(Theme.chalk)

                        let columns = [GridItem(.adaptive(minimum: 76), spacing: 8)]
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(engine.flatSurvivors) { fate in
                                KanjiTileView(char: fate.char)
                            }
                            ForEach(engine.flatDeleted) { fate in
                                SealedTile(lines: fate.state == .autoDeleted ? ["重", "複"] : ["没"],
                                           size: 72,
                                           angle: fate.state == .autoDeleted ? 8 : -8)
                            }
                        }
                        .padding(.horizontal, 8)

                        TextField("お題を入力", text: $answer)
                            .font(Theme.font(20))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .focused($focused)
                            .submitLabel(.done)
                            .onSubmit(submit)
                            .padding(.horizontal, 20)
                            .frame(height: 64)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.card)
                                    .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
                            )
                            .padding(.horizontal, 8)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
            }
        } actions: {
            ChalkButton(title: "回答する", enabled: !trimmed.isEmpty, action: submit)
        }
        .onAppear { answer = session.engine.answerText ?? "" }
    }

    private var trimmed: String { answer.trimmingCharacters(in: .whitespaces) }

    private func submit() {
        guard !trimmed.isEmpty else { return }
        focused = false
        session.update { $0.submitAnswer(trimmed) }
    }
}
