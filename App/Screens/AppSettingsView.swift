import SwiftUI

/// S20 アプリ設定
struct AppSettingsView: View {
    @Environment(AppState.self) private var app
    @Binding var path: NavigationPath

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
                .buttonStyle(.pressable)
                Button { path.append(HomeRoute.terms) } label: { linkRow("利用規約") }
                    .buttonStyle(.pressable)
                Button { path.append(HomeRoute.privacy) } label: { linkRow("プライバシーポリシー") }
                    .buttonStyle(.pressable)
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
