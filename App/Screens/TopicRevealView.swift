import SwiftUI
import KanjiCore

/// S07-B お題公開・お題表示（全員で一斉に見る）
struct TopicRevealView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        let engine = session.engine
        ChalkScreen(progress: session.progressLine, title: "お題を見る") {
            VStack(spacing: 20) {
                if let duration = engine.config.timer {
                    TimerChip(duration: duration)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if let topic = engine.topic {
                    VStack(spacing: 14) {
                        Text(difficultyLabel(topic.difficulty))
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.primaryDark)
                            .padding(.vertical, 4).padding(.horizontal, 12)
                            .background(Capsule().fill(Theme.primaryLight))
                        Text("お題")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.inkSecondary)
                        RubyText(text: topic.text, furigana: topic.furigana, size: 44)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.card)
                            .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
                    )
                }
                Button {
                    session.update { $0.skipTopic() }
                } label: {
                    Label("お題を引き直す", systemImage: "arrow.counterclockwise")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.primary)
                }
                .buttonStyle(.pressable)
                Label("回答者には 絶対に見せないでください", systemImage: "eye.slash")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkFaded)
            }
            .padding(.horizontal, 16)
        } actions: {
            ChalkButton(title: "みんな見終わった — ヒント入力へ") {
                session.update { $0.finishTopicViewing() }
            }
        }
    }

    private func difficultyLabel(_ d: Difficulty) -> String {
        switch d {
        case .easy: "やさしい"
        case .normal: "ふつう"
        case .hard: "むずかしい"
        }
    }
}
