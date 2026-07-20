import SwiftUI
import KanjiCore

/// S10-B お題を当てる（フラット表示＋回答入力）
struct AnswerInputView: View {
    @Environment(GameSession.self) private var session
    @State private var answer = ""

    var body: some View {
        let engine = session.engine
        ChalkScreen(progress: session.progressLine, title: "お題を当てる") {
            VStack(spacing: 24) {
                Text("生き残った漢字から お題を当ててください")
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.chalk)
                let columns = [GridItem(.adaptive(minimum: 80), spacing: 8)]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(engine.flatSurvivors) { fate in
                        KanjiTileView(char: fate.char)
                    }
                    ForEach(0..<engine.deletedCount, id: \.self) { _ in
                        GhostSlot()
                    }
                }
                .padding(.horizontal, 8)
                Text("順不同・グループなしで表示されています")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkFaded)
                TextField("お題を入力", text: $answer)
                    .font(Theme.font(20))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.card)
                            .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(maxHeight: .infinity, alignment: .top)
        } actions: {
            ChalkButton(title: "回答する", enabled: !answer.trimmingCharacters(in: .whitespaces).isEmpty) {
                session.update { $0.submitAnswer(answer.trimmingCharacters(in: .whitespaces)) }
            }
        }
        .onAppear { answer = session.engine.answerText ?? "" }
    }
}
