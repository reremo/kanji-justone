import SwiftUI
import KanjiCore

/// S06 回答者発表
struct AnswererRevealView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        let engine = session.engine
        ChalkScreen(
            progress: "ラウンド \(engine.roundNumber)/\(engine.config.rounds) ・ \(engine.turnNumber)/\(engine.turnsPerRound)人目",
            title: "回答者発表"
        ) {
            VStack(spacing: 22) {
                Text("このターンの回答者は…")
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.chalkFaded)
                VStack(spacing: 12) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.primaryDark)
                    Text(engine.answerer.name)
                        .font(Theme.font(44))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.card)
                        .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 4)
                )
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.primary, lineWidth: 3))
                Text("ほかのみんなは ヒントを出す人です")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkFaded)
            }
            .padding(.horizontal, 24)
        } actions: {
            ChalkButton(title: "OK") {
                session.update { $0.proceedFromAnswererReveal() }
            }
        }
    }
}
