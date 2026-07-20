import SwiftUI

/// S19 ショップ（StoreKit連携は後続。ローカルフラグで解除動作を確認できる）
struct ShopView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        NavScreen(title: "ショップ") {
            if app.purchased {
                purchasedBody
            } else {
                storeBody
            }
        } actions: {
            if app.purchased {
                Button {
                    Task { await app.store.restore() }
                } label: {
                    Text("購入を復元する")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.chalkFaded)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
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

    // 購入済み（案B: お礼レイアウト）
    private var purchasedBody: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.success)
            Text("ありがとうございます！")
                .font(Theme.font(26))
                .foregroundStyle(Theme.chalk)
            Text("「全部解除パック」を購入済みです。\nすべての機能が使えます。")
                .font(Theme.font(15))
                .foregroundStyle(Theme.chalkFaded)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 10) {
                feature("広告なし")
                feature("ラウンド数むせいげん")
                feature("ヒントの文字数へんこう")
                feature("通常お題ぜんぶ＋自作お題")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.card)
                    .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
            )
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    // 未購入（購入訴求）
    private var storeBody: some View {
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
    }

    private func feature(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.success)
            Text(text)
                .font(Theme.font(14))
                .foregroundStyle(Theme.ink)
        }
    }
}
