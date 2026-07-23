import SwiftUI
import KanjiCore

/// お題テキスト表示。v1ではルビ（ふりがな）表示は見送り、本文のみを出す。
/// 長いお題は1行に収まるよう自動縮小する。furigana はデータとして受け取るが表示しない。
struct RubyText: View {
    let text: String
    var furigana: String = ""
    var size: CGFloat = 40
    var color: Color = Theme.ink

    var body: some View {
        Text(text)
            .font(Theme.font(size))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
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
