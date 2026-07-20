import SwiftUI
import KanjiCore

/// ふりがな付きテキスト（MVP: かな小サイズを上に重ねる簡易実装）
struct RubyText: View {
    let text: String
    let furigana: String
    var size: CGFloat = 40
    var color: Color = Theme.ink

    var body: some View {
        VStack(spacing: 2) {
            if furigana != text {
                Text(furigana)
                    .font(Theme.font(max(11, size * 0.28)))
                    .foregroundStyle(color.opacity(0.65))
            }
            Text(text)
                .font(Theme.font(size))
                .foregroundStyle(color)
        }
    }
}

/// 黒板地に小さくお題を示す行（S09/S13ヘッダー下用）
struct TopicRow: View {
    let topic: Topic
    var size: CGFloat = 28

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text("お題")
                .font(Theme.font(13))
                .foregroundStyle(Theme.chalkFaded)
            RubyText(text: topic.text, furigana: topic.furigana, size: size, color: Theme.chalk)
        }
    }
}
