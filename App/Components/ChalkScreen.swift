import SwiftUI

/// 3層ゾーン（ヘッダー帯 / 作業ボード / 操作帯）の画面骨格
struct ChalkScreen<Content: View, Actions: View>: View {
    var background: Color = Theme.board
    var progress: String?
    var title: String
    var titleColor: Color = Theme.chalk
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                if let progress {
                    Text(progress)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                }
                Text(title)
                    .font(Theme.font(24))
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background(Theme.band)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.bandLine).frame(height: 2)
            }

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 10) {
                actions()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Theme.band)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.bandLine).frame(height: 2)
            }
        }
        .background(background.ignoresSafeArea())
    }
}
