import Foundation

public enum HintValidationError: Error, Equatable {
    case notKanji(Character)
    case duplicateOwnChar(Character)
    case wrongLength
}

public enum HintRules {
    /// 漢字判定: CJK統合漢字（U+4E00–U+9FFF）＋拡張A（U+3400–U+4DBF）のみ許可。
    /// 「々」「〆」等の記号・かな・英数は不可。
    public static func isKanji(_ c: Character) -> Bool {
        let scalars = Array(c.unicodeScalars)
        guard scalars.count == 1 else { return false }
        let v = scalars[0].value
        return (0x4E00...0x9FFF).contains(v) || (0x3400...0x4DBF).contains(v)
    }

    /// ヒント入力のバリデーション。問題なければ nil。
    public static func validate(chars: [Character], expectedCount: Int) -> HintValidationError? {
        guard chars.count == expectedCount else { return .wrongLength }
        for c in chars where !isKanji(c) {
            return .notKanji(c)
        }
        var seen = Set<Character>()
        for c in chars {
            if seen.contains(c) { return .duplicateOwnChar(c) }
            seen.insert(c)
        }
        return nil
    }
}
