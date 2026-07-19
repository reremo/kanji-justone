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
            VStack(spacing: 20) {
                Text("このターンの回答者は…")
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.chalkFaded)
                VStack(spacing: 8) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.primaryDark)
                    Text("\(engine.answerer.name) さん")
                        .font(Theme.font(40))
                        .foregroundStyle(Theme.ink)
                    Text("お題を当てる人")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.card)
                        .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 4)
                )
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.primary, lineWidth: 3))
                Text("ほかのみんなは ヒントを出す人です")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkFaded)
            }
            .padding(.horizontal, 24)
        } actions: {
            ChalkButton(title: "OK — お題公開へ") {
                session.update { $0.proceedFromAnswererReveal() }
            }
        }
    }
}
