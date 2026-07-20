import SwiftUI

/// S02 遊び方
struct HowToView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        "回答者以外で お題をこっそり見る",
        "1人ずつ 漢字でヒントを出す",
        "かぶった文字は消えてしまう！かぶらない字を選ぼう",
        "残った漢字だけで 回答者が当てる",
        "当たったら 回答者もヒントを出した人も得点！",
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
                Text("※ お題の漢字そのものや、自分の文字で実在する言葉を作るのはNG！")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkFaded)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        } actions: {
            ChalkButton(title: "わかった！") { dismiss() }
        }
    }
}
