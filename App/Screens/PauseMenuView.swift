import SwiftUI

/// プレイ中の一時中断メニュー（サウンド切替・中断・破棄）
struct PauseMenuView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmQuit = false

    var body: some View {
        @Bindable var app = app
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.primary)
                Text("一時中断")
                    .font(Theme.font(22))
                    .foregroundStyle(Theme.chalk)
            }
            .padding(.top, 24)
            .padding(.bottom, 4)

            CardRow {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSecondary)
                Text("サウンド")
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Toggle("", isOn: $app.soundOn)
                    .labelsHidden()
                    .tint(Theme.primaryDark)
            }

            menuRow(title: "中断してホームへ", subtitle: "あとで再開できます",
                    icon: "house.fill", tint: Theme.ink) {
                dismiss()
                app.suspendGame()
            }
            menuRow(title: "ゲームをやめる", subtitle: "進行を破棄します（記録に残りません）",
                    icon: "xmark.circle.fill", tint: Theme.error) {
                confirmQuit = true
            }

            ChalkButton(title: "つづける") {
                dismiss()
            }
            .padding(.top, 4)
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

    private func menuRow(title: String, subtitle: String, icon: String, tint: Color,
                         action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            CardRow {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(tint)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.font(16))
                        .foregroundStyle(tint)
                    Text(subtitle)
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .padding(.vertical, 10)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkDisabled)
            }
        }
        .buttonStyle(.plain)
    }
}
