import SwiftUI

/// 秘匿の受け渡し・確認ゲート（深黒板の全面画面）
struct HandoffGateView: View {
    var phaseLabel: String = ""
    var icon: String = "eye.slash"
    var lead: String = ""
    let headline: String
    var note: String?
    let buttonTitle: String
    let action: () -> Void
    /// 誤タップ防止: 表示直後0.5秒はボタンを無効化する（UXガイドライン準拠）
    @State private var buttonEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                if !phaseLabel.isEmpty {
                    Text(phaseLabel)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkDim)
                }
                Image(systemName: icon)
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.primary)
                if !lead.isEmpty {
                    Text(lead)
                        .font(Theme.font(18))
                        .foregroundStyle(Theme.chalkFaded)
                }
                Text(headline)
                    .font(Theme.font(34))
                    .foregroundStyle(Theme.chalk)
                    .multilineTextAlignment(.center)
                if let note {
                    Text(note)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkDim)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
            ChalkButton(title: buttonTitle, enabled: buttonEnabled, action: action)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.boardDark.ignoresSafeArea())
        .task {
            buttonEnabled = false
            try? await Task.sleep(for: .milliseconds(500))
            buttonEnabled = true
        }
    }
}
