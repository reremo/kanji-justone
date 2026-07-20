import SwiftUI

/// 戻るボタン付きのナビゲーション画面骨格（ホーム配下の各画面用）
struct NavScreen<Content: View, Actions: View>: View {
    var background: Color = Theme.board
    let title: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions
    @Environment(\.dismiss) private var dismiss

    init(background: Color = Theme.board,
         title: String,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }) {
        self.background = background
        self.title = title
        self.content = content
        self.actions = actions
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.chalk)
                }
                .buttonStyle(.pressable)
                Text(title)
                    .font(Theme.font(24))
                    .foregroundStyle(Theme.chalk)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background(Theme.band)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.bandLine).frame(height: 2)
            }

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if Actions.self != EmptyView.self {
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
        }
        .background(background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// 白カード行の共通スタイル
struct CardRow<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            content()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
        )
    }
}
