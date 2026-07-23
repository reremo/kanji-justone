import SwiftUI

/// 朱印スタンプ（角印）。没・重複の表現に使う。半透過で下の漢字が透ける。
struct SealStamp: View {
    let lines: [String]        // ["没"] または ["重", "複"]
    var size: CGFloat = 72
    var angle: Double = -11

    var body: some View {
        let single = lines.count == 1
        VStack(spacing: size * 0.02) {
            ForEach(lines, id: \.self) { s in
                Text(s)
                    .font(Theme.font(size * (single ? 0.44 : 0.28)))
            }
        }
        .foregroundStyle(Theme.seal)
        .frame(width: size * 0.76, height: size * 0.76)
        .background(
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(Theme.seal.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.12)
                .strokeBorder(Theme.seal, lineWidth: max(2.5, size * 0.06))
        )
        .rotationEffect(.degrees(angle))
        .opacity(0.9)
    }
}

/// 消えた漢字の公開札：字を見せた上に没／重複の透過朱印を重ねる（結果・発表用）
struct RevealedKanjiTile: View {
    let char: Character
    let manual: Bool           // true=没(手動)／false=重複(自動)
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Theme.tileDeletedBg)
                .overlay(RoundedRectangle(cornerRadius: size * 0.2).strokeBorder(Theme.tileBorder, lineWidth: 2))
            Text(String(char))
                .font(Theme.font(size * 0.55))
                .foregroundStyle(Theme.inkDisabled)
            SealStamp(lines: manual ? ["没"] : ["重", "複"], size: size, angle: manual ? -8 : 8)
        }
        .frame(width: size, height: size)
    }
}

/// 朱印を押した白カード（重複／消えた札）。字は伏せる。没・重複・消えたで統一デザイン。
struct SealedTile: View {
    let lines: [String]        // ["重", "複"] / ["消"] など
    var size: CGFloat = 72
    var angle: Double = 8

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .strokeBorder(Theme.tileBorder, lineWidth: 2)
                )
            SealStamp(lines: lines, size: size, angle: angle)
        }
        .frame(width: size, height: size)
    }
}
