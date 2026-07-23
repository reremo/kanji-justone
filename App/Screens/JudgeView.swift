import SwiftUI
import KanjiCore

/// S11 答え合わせ。真緑の全画面 → タップで お題 → 遅れて回答 → 落ち着いたら判定ボタン、と順に立ち上げる。
struct JudgeView: View {
    @Environment(GameSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var started = false
    @State private var showTopic = false
    @State private var showAnswer = false
    @State private var showButtons = false

    var body: some View {
        let engine = session.engine
        ZStack {
            Theme.board.ignoresSafeArea()

            if started {
                revealStage(engine: engine)
            } else {
                intro
            }
        }
    }

    // MARK: - 導入（真緑・タップ待ち）

    private var intro: some View {
        VStack(spacing: 16) {
            Text("答え合わせ")
                .font(Theme.font(34))
                .foregroundStyle(Theme.chalk)
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.primary)
            Text("タップしてめくる")
                .font(Theme.font(15))
                .foregroundStyle(Theme.chalkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { start() }
    }

    // MARK: - 演出（お題 → 回答 → 判定）

    private func revealStage(engine: GameEngine) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // お題（主役）
            VStack(spacing: 10) {
                Text("お題")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkDim)
                Text(engine.topic?.text ?? "")
                    .font(Theme.font(48))
                    .foregroundStyle(Theme.chalk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .shadow(color: Theme.primary.opacity(showTopic ? 0.35 : 0), radius: 18)
            }
            .padding(.horizontal, 24)
            .opacity(showTopic ? 1 : 0)
            .scaleEffect(showTopic ? 1 : 0.82)

            // 回答者の答え（遅れて・小さめ）
            VStack(spacing: 6) {
                Text("\(engine.answerer.name)さんの回答")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkDim)
                Text(engine.answerText ?? "")
                    .font(Theme.font(28))
                    .foregroundStyle(Theme.chalkFaded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
            .padding(.top, 34)
            .padding(.horizontal, 24)
            .opacity(showAnswer ? 1 : 0)
            .offset(y: showAnswer ? 0 : 14)

            Spacer(minLength: 0)

            // 判定ボタン（落ち着いてから）
            VStack(spacing: 10) {
                Text("ヒントを出したみんなで 判定してください")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkFaded)
                    .padding(.bottom, 2)
                ChalkButton(title: "正解！") {
                    session.update { $0.judgeCorrect() }
                }
                ChalkButton(title: "不正解", style: .outline) {
                    session.update { $0.judgeWrong() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .opacity(showButtons ? 1 : 0)
            .offset(y: showButtons ? 0 : 18)
            .allowsHitTesting(showButtons)
        }
    }

    // MARK: - シーケンス

    private func start() {
        started = true
        Haptics.light()
        SoundPlayer.play(.tap)

        if reduceMotion {
            showTopic = true; showAnswer = true; showButtons = true
            return
        }

        Task {
            withAnimation(.spring(duration: 0.55, bounce: 0.42)) { showTopic = true }
            try? await Task.sleep(for: .milliseconds(850))
            Haptics.light()
            withAnimation(.easeOut(duration: 0.45)) { showAnswer = true }
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(.easeOut(duration: 0.4)) { showButtons = true }
        }
    }
}
