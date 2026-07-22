import SwiftUI

/// S02 遊び方
struct HowToView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        "回答者以外で お題を見る",
        "お題を連想する漢字を 1人ずつ出す",
        "他人と被ったヒントの漢字は消える。かぶらない字を選ぶ かけひき",
        "最終的に残った漢字で 回答者が当てる",
        "当たれば 回答者もヒントを出した人も得点",
    ]

    var body: some View {
        NavScreen(title: "遊び方") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    CardRow {
                        Text("\(index + 1)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.primary))
                        Text(step)
                            .font(Theme.font(15))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 12)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        } actions: {
            ChalkButton(title: "わかった！") { dismiss() }
        }
    }
}
