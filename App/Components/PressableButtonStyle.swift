import SwiftUI

/// 押した瞬間に縮んで少し暗くなる、共通の押下フィードバック。
/// タップの手応えを全ボタンで統一する。
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// 標準の押下フィードバック
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    /// 小さめ要素向け（控えめな縮み）
    static var pressableSubtle: PressableButtonStyle { PressableButtonStyle(scale: 0.9) }
}
