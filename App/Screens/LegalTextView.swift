import SwiftUI

/// 利用規約・プライバシーポリシーの全文表示（スクロール）
struct LegalTextView: View {
    let title: String
    let content: String

    var body: some View {
        NavScreen(title: title) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, block in
                        block.view
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.card)
                        .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 3)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
    }

    private enum Block {
        case h1(String), h2(String), text(String)

        @ViewBuilder var view: some View {
            switch self {
            case .h1(let s):
                Text(s).font(Theme.font(22)).foregroundStyle(Theme.ink)
            case .h2(let s):
                Text(s).font(Theme.font(16)).foregroundStyle(Theme.ink).padding(.top, 6)
            case .text(let s):
                Text(s).font(Theme.font(14)).foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
            }
        }
    }

    private var paragraphs: [Block] {
        content.components(separatedBy: "\n").compactMap { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { return nil }
            if t.hasPrefix("## ") { return .h2(String(t.dropFirst(3))) }
            if t.hasPrefix("# ") { return .h1(String(t.dropFirst(2))) }
            return .text(t)
        }
    }
}
