import SwiftUI

/// docs/design/ux-guidelines.md のデザイントークン
enum Theme {
    // 背景
    static let board = Color(hex: 0x2C5545)          // 黒板緑（通常画面の地）
    static let boardDark = Color(hex: 0x1D3A2F)      // 秘匿ロック・受け渡し
    static let boardBright = Color(hex: 0x2F5B49)    // 結果発表の地
    static let band = Color(hex: 0x24483A)           // ヘッダー帯・操作帯
    static let bandLine = Color(hex: 0x4E7561)       // 帯の罫線
    static let card = Color.white

    // チョーク文字（黒板地上）
    static let chalk = Color(hex: 0xFDFBF2)
    static let chalkFaded = Color(hex: 0xC9D6C0)
    static let chalkDim = Color(hex: 0xA9BFA9)       // 暗い板面の補足
    static let chalkPink = Color(hex: 0xFFA8BE)      // 祝祭アクセント
    static let chalkWarn = Color(hex: 0xFFB3A8)      // 黒板地上の警告・削除系

    // カード上の文字
    static let ink = Color(hex: 0x2B2B2B)
    static let inkSecondary = Color(hex: 0x6B6B6B)
    static let inkDisabled = Color(hex: 0xA8A8A8)

    // プライマリ（チョーク黄）
    static let primary = Color(hex: 0xF7C948)
    static let primaryDark = Color(hex: 0xC99B1F)
    static let primaryLight = Color(hex: 0xFBF0CE)

    // セマンティック
    static let success = Color(hex: 0x2E9E5B)
    static let error = Color(hex: 0xE23D3D)
    static let seal = Color(hex: 0xC02A2A)           // 朱印（没・重複スタンプ）

    // 漢字カード
    static let tileBorder = Color(hex: 0xE6DFCE)
    static let tileShadow = Color(hex: 0x1F4032)
    static let tileDeletedBg = Color(hex: 0xEDE7D8)
    static let ghostFill = Color(hex: 0x26493C)
    static let ghostIcon = Color(hex: 0x5F8370)

    static func font(_ size: CGFloat) -> Font {
        .custom("KosugiMaru-Regular", size: size)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
