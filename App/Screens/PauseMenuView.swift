import SwiftUI

/// プレイ中の一時中断（全画面ポーズ・デザイン案C）
struct PauseMenuView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmQuit = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "pause.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.primary)
            Text("一時中断")
                .font(Theme.font(30))
                .foregroundStyle(Theme.chalk)
            Button {
                Haptics.light()
                app.soundOn.toggle()
            } label: {
                Label("サウンド \(app.soundOn ? "ON" : "OFF")",
                      systemImage: app.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(Theme.font(14))
                    .foregroundStyle(app.soundOn ? Theme.chalk : Theme.chalkDim)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 1.5))
            }
            .buttonStyle(.pressable)
            Spacer()
            VStack(spacing: 12) {
                ChalkButton(title: "つづける") {
                    dismiss()
                }
                ChalkButton(title: "中断してホームへ", style: .light) {
                    dismiss()
                    app.suspendGame()
                }
                ChalkButton(title: "ゲームをやめる", style: .warnOutline) {
                    confirmQuit = true
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.boardDark.ignoresSafeArea())
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
