import SwiftUI

enum ChalkButtonStyle {
    case primary      // チョーク黄・ピル・押し込みエッジ
    case light        // チョーク白の塗り・墨ラベル
    case outline      // チョーク白の枠線
    case warnOutline  // 黒板地上の警告ピンク枠線
}

struct ChalkButton: View {
    let title: String
    var style: ChalkButtonStyle = .primary
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.light()
            SoundPlayer.play(.tap)
            action()
        } label: {
            Text(title)
                .font(Theme.font(style == .primary ? 17 : 16))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: style == .primary ? 56 : 52)
                .background(backgroundShape)
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    private var foreground: Color {
        switch style {
        case .primary, .light: Theme.ink
        case .outline: Theme.chalk
        case .warnOutline: Theme.chalkWarn
        }
    }

    @ViewBuilder private var backgroundShape: some View {
        switch style {
        case .primary:
            Capsule()
                .fill(Theme.primary)
                .shadow(color: Theme.primaryDark, radius: 0, x: 0, y: 4)
        case .light:
            Capsule().fill(Theme.chalk)
        case .outline:
            Capsule().strokeBorder(Theme.chalkFaded, lineWidth: 2)
        case .warnOutline:
            Capsule().strokeBorder(Theme.chalkWarn, lineWidth: 2)
        }
    }
}
