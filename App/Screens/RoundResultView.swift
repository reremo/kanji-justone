import SwiftUI
import KanjiCore

/// S14 中間スコア（簡易版）
struct RoundResultView: View {
    @Environment(GameSession.self) private var session
    @Environment(AppState.self) private var app

    var body: some View {
        let engine = session.engine
        ChalkScreen(
            background: Theme.boardBright,
            progress: "ラウンド \(engine.roundNumber)/\(engine.config.rounds) 終了",
            title: "中間スコア"
        ) {
            ScoreListView(engine: engine)
        } actions: {
            ChalkButton(title: "ラウンド \(engine.roundNumber + 1) へ！") {
                let proceed = { session.update { $0.proceedFromRoundResult() } }
                if app.purchased {
                    proceed()
                } else {
                    // 無料版はラウンド結果の後にインタースティシャル（要件準拠）
                    app.ads.showInterstitial(completion: proceed)
                }
            }
        }
    }
}

/// S15 最終結果（簡易版）
struct FinalResultView: View {
    @Environment(GameSession.self) private var session
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showConfetti = false

    var body: some View {
        let engine = session.engine
        ChalkScreen(
            background: Theme.boardBright,
            progress: "全ラウンド終了",
            title: "最終結果！",
            titleColor: Theme.chalkPink
        ) {
            ScoreListView(engine: engine, crownForFirst: true)
                .overlay {
                    if showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                            .ignoresSafeArea()
                    }
                }
                .onAppear {
                    Haptics.success()
                    SoundPlayer.play(.fanfare)
                    if !reduceMotion { showConfetti = true }
                }
        } actions: {
            ChalkButton(title: "もう一度あそぶ") {
                try? app.startGame()
            }
            ChalkButton(title: "ホームへ戻る", style: .outline) {
                app.endGame()
            }
        }
    }
}

private struct ScoreListView: View {
    let engine: GameEngine
    var crownForFirst: Bool = false

    var body: some View {
        let ranked = engine.config.players.sorted {
            (engine.totalScores[$0.id] ?? 0) > (engine.totalScores[$1.id] ?? 0)
        }
        VStack(spacing: 12) {
            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 12) {
                    if index == 0 && crownForFirst {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color(hex: 0xD9A62E))
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Text(player.name)
                        .font(Theme.font(18))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(engine.totalScores[player.id] ?? 0)点")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 16)
                .frame(height: 60)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(index == 0 && crownForFirst ? Color(hex: 0xD9A62E) : .clear, lineWidth: 2.5)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
}
