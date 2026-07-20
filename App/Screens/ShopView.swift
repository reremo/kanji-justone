import SwiftUI

/// S19 ショップ（StoreKit連携は後続。ローカルフラグで解除動作を確認できる）
struct ShopView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        NavScreen(title: "ショップ") {
            VStack(spacing: 16) {
                Spacer()
                VStack(spacing: 14) {
                    Text("買い切り・ひとつだけ")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.ink)
                        .padding(.vertical, 4).padding(.horizontal, 14)
                        .background(Capsule().fill(Theme.chalkPink))
                    Text("全部解除パック")
                        .font(Theme.font(26))
                        .foregroundStyle(Theme.ink)
                    VStack(alignment: .leading, spacing: 10) {
                        feature("広告が出なくなる")
                        feature("ラウンド数の上限を解除")
                        feature("ヒントの文字数を変えられる")
                        feature("通常お題 全部＋自作お題モード")
                    }
                    Text(app.store.product?.displayPrice ?? "¥600")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryDark)
                    if let error = app.store.lastError {
                        Text(error)
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Theme.card)
                        .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 4)
                )
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.primary, lineWidth: 3))
                .padding(.horizontal, 16)
                Spacer()
            }
        } actions: {
            if app.purchased {
                Text("購入済み — すべて解除されています")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.chalkFaded)
                    .frame(height: 44)
            } else {
                ChalkButton(title: "\(app.store.product?.displayPrice ?? "¥600") で 全部解除",
                            enabled: app.store.product != nil && !app.store.purchasing) {
                    Task { await app.store.purchase() }
                }
                Button {
                    Task { await app.store.restore() }
                } label: {
                    Text("購入を復元する")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.chalkFaded)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func feature(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(Theme.font(14))
            .foregroundStyle(Theme.ink)
            .symbolRenderingMode(.palette)
            .foregroundStyle(Theme.success, Theme.success.opacity(0.15))
    }
}
