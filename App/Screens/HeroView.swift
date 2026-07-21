import SwiftUI

/// ホーム上部のヒーロー。宙に浮かぶ漢字タイルの中央に「漢字の力」を大きく主張する。
struct HeroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false
    @State private var appeared = false
    @State private var twinkle = false

    // (漢字, サイズ, 回転°, x比率, y比率, 不透明度)。比率はヒーロー領域基準
    private let tiles: [(String, CGFloat, Double, CGFloat, CGFloat, Double)] = [
        ("空", 40, -18, 0.09, 0.14, 0.45),
        ("夢", 38,  20, 0.87, 0.12, 0.40),
        ("念", 40, -12, 0.12, 0.64, 0.45),
        ("音", 36,  15, 0.88, 0.68, 0.40),
        ("問", 34,   8, 0.48, 0.07, 0.40),
        ("答", 34, -10, 0.47, 0.92, 0.40),
        ("山", 54, -10, 0.10, 0.38, 0.80),
        ("光", 54,  12, 0.85, 0.40, 0.80),
        ("風", 50,  -8, 0.14, 0.86, 0.70),
        ("星", 48,  10, 0.83, 0.85, 0.70),
    ]

    // (記号, サイズ, x比率, y比率, 色, 不透明度)
    private let sparks: [(String, CGFloat, CGFloat, CGFloat, Color, Double)] = [
        ("？", 30, 0.32, 0.12, Theme.primary, 0.9),
        ("✦", 22, 0.72, 0.20, Theme.primary, 0.85),
        ("？", 20, 0.80, 0.96, Theme.chalkFaded, 0.7),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 浮遊タイル（登場時は外側から中央へふわっと集まりながら出現）
                ForEach(Array(tiles.enumerated()), id: \.offset) { i, t in
                    tileView(char: t.0, size: t.1)
                        .rotationEffect(.degrees(t.2 + (floating ? 3.5 : -3.5)))
                        .opacity(appeared ? t.5 : 0)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .offset(x: appeared ? 0 : (t.3 - 0.5) * w * 0.35,
                                y: appeared ? 0 : (t.4 - 0.5) * h * 0.35)
                        .animation(entrance(Double(i) * 0.045), value: appeared)
                        .position(x: w * t.3, y: h * t.4)
                        .offset(y: floating ? drift(i) : -drift(i))
                        .animation(driftAnimation(i), value: floating)
                }
                // ひらめき記号
                ForEach(Array(sparks.enumerated()), id: \.offset) { i, s in
                    Text(s.0)
                        .font(Theme.font(s.1))
                        .foregroundStyle(s.4)
                        .opacity(appeared ? (twinkle ? s.5 : s.5 * 0.45) : 0)
                        .scaleEffect(twinkle ? 1.18 : 0.92)
                        .animation(entrance(0.22 + Double(i) * 0.05), value: appeared)
                        .animation(twinkleAnimation(i), value: twinkle)
                        .position(x: w * s.2, y: h * s.3)
                }
                // 中央タイトル
                VStack(spacing: 8) {
                    Text("漢字の力")
                        .font(Theme.font(52))
                        .foregroundStyle(Theme.chalk)
                    Text("ことばを伝えあう 推理パーティ")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.chalkFaded)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)
                .animation(entrance(0.12), value: appeared)
                .position(x: w / 2, y: h * 0.5)
            }
        }
        .onAppear {
            appeared = true
            if !reduceMotion { floating = true; twinkle = true }
        }
    }

    private func tileView(char: String, size: CGFloat) -> some View {
        Text(char)
            .font(Theme.font(size * 0.55))
            .foregroundStyle(Theme.ink)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(Theme.card)
                    .shadow(color: Theme.tileShadow.opacity(0.33), radius: 0, x: 0, y: 3)
            )
    }

    // 登場アニメ（reduceMotion時は nil で即時反映）
    private func entrance(_ delay: Double) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.82).delay(delay)
    }

    // ひらめき記号の弱い明滅（位置ごとに速さをずらす）
    private func twinkleAnimation(_ i: Int) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: [1.8, 2.4, 2.1][i % 3]).repeatForever(autoreverses: true)
    }

    // タイルごとに少し違う漂い幅と速さ
    private func drift(_ i: Int) -> CGFloat { [10, 14, 11, 8, 13][i % 5] }
    private func driftAnimation(_ i: Int) -> Animation {
        .easeInOut(duration: [2.6, 3.2, 2.9, 3.5, 2.4][i % 5]).repeatForever(autoreverses: true)
    }
}
