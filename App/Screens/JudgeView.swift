import SwiftUI
import KanjiCore

/// S11 答え合わせ（正解／不正解／ギブアップ）
struct JudgeView: View {
    @Environment(GameSession.self) private var session
    @State private var revealed = false

    var body: some View {
        let engine = session.engine
        ChalkScreen(progress: session.progressLine, title: "答え合わせ") {
            VStack(spacing: 16) {
                card(label: "\(engine.answerer.name)さんの回答") {
                    Text(engine.answerText ?? "")
                        .font(Theme.font(32))
                        .foregroundStyle(Theme.ink)
                }
                if revealed {
                    card(label: "お題", highlighted: true) {
                        if let topic = engine.topic {
                            RubyText(text: topic.text, furigana: topic.furigana, size: 38)
                        }
                    }
                } else {
                    // 回答者の手元でお題が見えないよう、出題者が受け取ってからタップで表示する
                    card(label: "お題", highlighted: true) {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.inkSecondary)
                            Text("ヒントを出した人が受け取ったら\nタップして表示")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .onTapGesture { revealed = true }
                }
                Text("ヒントを出したみんなで 判定してください")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkFaded)
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
        } actions: {
            ChalkButton(title: "正解！") {
                session.update { $0.judgeCorrect() }
            }
            ChalkButton(title: "不正解 — もう一度答える", style: .outline) {
                session.update { $0.judgeWrong() }
            }
            ChalkButton(title: "ギブアップ（全員0点）", style: .warnOutline) {
                session.update { $0.judgeGiveUp() }
            }
        }
    }

    @ViewBuilder
    private func card(label: String, highlighted: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(Theme.font(13))
                .foregroundStyle(Theme.inkSecondary)
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(highlighted ? Theme.primary : .clear, lineWidth: 2.5)
        )
    }
}
