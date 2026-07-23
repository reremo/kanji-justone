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
