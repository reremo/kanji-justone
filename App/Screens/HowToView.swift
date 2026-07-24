import SwiftUI

/// S02 遊び方
struct HowToView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(main: String, subs: [String])] = [
        ("回答者以外で お題を確認する", []),
        ("お題を連想する漢字を 1人ずつ出す", [
            "他人と被ったヒントの漢字は消えてしまう。かぶらないよう、かけひきしよう",
            "お題に含まれる漢字は使わない",
            "お題を和訳しただけの漢字は使わない",
            "漢字を組み合わせて熟語を作らない",
        ]),
        ("全員の書いた漢字を見て 回答者がお題を当てる", []),
        ("当たれば 回答者もヒントを出した人も得点", [
            "役に立ったヒントを出した人ほど高得点",
            "消えた漢字が多いほど回答者にボーナス点",
        ]),
    ]

    var body: some View {
        NavScreen(title: "遊び方") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        StepCard(number: index + 1, main: step.main, subs: step.subs)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        } actions: {
            ChalkButton(title: "わかった！") { dismiss() }
        }
    }
}

private struct StepCard: View {
    let number: Int
    let main: String
    let subs: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.primary))
            VStack(alignment: .leading, spacing: subs.isEmpty ? 0 : 8) {
                Text(main)
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 32, alignment: .center)
                ForEach(subs, id: \.self) { sub in
                    HStack(alignment: .top, spacing: 6) {
                        Text("・")
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.inkSecondary)
                        Text(sub)
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
        )
    }
}
