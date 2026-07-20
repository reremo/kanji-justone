import SwiftUI
import KanjiCore

/// 黒板に貼った白い漢字カード
struct KanjiTileView: View {
    let char: Character
    var size: CGFloat = 72
    var deleted: Bool = false
    var selected: Bool = false

    var body: some View {
        Text(String(char))
            .font(Theme.font(size * 0.55))
            .foregroundStyle(deleted ? Theme.inkDisabled : Theme.ink)
            .strikethrough(deleted)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(deleted ? Theme.tileDeletedBg : Theme.card)
                    .shadow(color: deleted ? .clear : Theme.tileShadow, radius: 0, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .strokeBorder(selected ? Theme.error : (deleted ? .clear : Theme.tileBorder),
                                  lineWidth: selected ? 2.5 : 2)
            )
    }
}

/// 消えた枠（削除された文字の残骸スロット）
struct GhostSlot: View {
    var size: CGFloat = 72

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.14)
            .fill(Theme.ghostFill)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.14)
                    .strokeBorder(Theme.bandLine, lineWidth: 2)
            )
            .overlay(
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(Theme.ghostIcon)
            )
            .frame(width: size, height: size)
    }
}
