import SwiftUI

/// S20 アプリ設定
struct AppSettingsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        NavScreen(title: "設定") {
            VStack(spacing: 10) {
                CardRow {
                    Text("サウンド")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Toggle("", isOn: $app.soundOn)
                        .labelsHidden()
                        .tint(Theme.primaryDark)
                }
                Button {
                    Task { await app.store.restore() }
                } label: {
                    linkRow("購入の復元")
                }
                .buttonStyle(.plain)
                linkRow("利用規約")
                linkRow("プライバシーポリシー")
                Text("漢字ジャストワン v0.1.0（開発版）")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.chalkFaded)
                    .padding(.top, 12)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }

    private func linkRow(_ title: String) -> some View {
        CardRow {
            Text(title)
                .font(Theme.font(15))
                .foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkDisabled)
        }
    }
}
