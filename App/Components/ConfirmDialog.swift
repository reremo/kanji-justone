import SwiftUI

/// 黒板×チョークのテーマに合わせた確認モーダル。
/// システムの confirmationDialog / alert の代わりに使う。
struct ConfirmDialog: View {
    let title: String
    var message: String? = nil
    let confirmTitle: String
    var confirmStyle: ChalkButtonStyle = .primary
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            VStack(spacing: 18) {
                Text(title)
                    .font(Theme.font(20))
                    .foregroundStyle(Theme.chalk)
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                VStack(spacing: 10) {
                    ChalkButton(title: confirmTitle, style: confirmStyle) { onConfirm() }
                    ChalkButton(title: "キャンセル", style: .light) { onCancel() }
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.boardBright)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.chalkFaded, lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
            )
            .padding(.horizontal, 32)
        }
    }
}
