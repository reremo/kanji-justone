import SwiftUI

/// S10-A お題を当てる・受け渡し（本人確認は不要。生存漢字は公開情報）
struct AnswerHandoffView: View {
    @Environment(GameSession.self) private var session

    var body: some View {
        let name = session.engine.answerer.name
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Text("お題を当てる")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkFaded)
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.ghostIcon)
                Text("回答者の \(name)さんに\n渡してください")
                    .font(Theme.font(30))
                    .foregroundStyle(Theme.chalk)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            ChalkButton(title: "渡した — お題を当てる") {
                session.update { $0.answererReceived() }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.board.ignoresSafeArea())
    }
}
