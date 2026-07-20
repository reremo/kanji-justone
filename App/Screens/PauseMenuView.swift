import SwiftUI

/// プレイ中の一時中断メニュー（サウンド切替・中断・破棄）
struct PauseMenuView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmQuit = false

    var body: some View {
        @Bindable var app = app
        VStack(spacing: 14) {
            Text("一時中断")
                .font(Theme.font(20))
                .foregroundStyle(Theme.chalk)
                .padding(.top, 20)
            CardRow {
                Text("サウンド")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Toggle("", isOn: $app.soundOn)
                    .labelsHidden()
                    .tint(Theme.primaryDark)
            }
            ChalkButton(title: "つづける") {
                dismiss()
            }
            ChalkButton(title: "中断してホームへ（あとで再開できる）", style: .outline) {
                dismiss()
                app.suspendGame()
            }
            ChalkButton(title: "ゲームをやめる", style: .warnOutline) {
                confirmQuit = true
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.band.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .alert("ゲームをやめますか？", isPresented: $confirmQuit) {
            Button("やめる", role: .destructive) {
                dismiss()
                app.abandonGame()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このゲームの進行は破棄され、記録にも残りません")
        }
    }
}
