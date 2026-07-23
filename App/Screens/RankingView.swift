import SwiftUI
import KanjiCore

/// S12 役に立った順に並べる（回答者による採点）
struct RankingView: View {
    @Environment(GameSession.self) private var session
    @State private var order: [CharFate] = []
    @State private var gatePassed = false

    var body: some View {
        if gatePassed {
            rankingScreen
        } else {
            let name = session.engine.answerer.name
            HandoffGateView(
                icon: "iphone.gen3",
                lead: "ヒントの順位付けを行います。\(name)さんに渡してください",
                headline: "\(name)さんですか？",
                buttonTitle: "はい、\(name)です"
            ) {
                gatePassed = true
            }
        }
    }

    private var rankingScreen: some View {
        let engine = session.engine
        return ChalkScreen(progress: session.progressLine, title: "ヒントになった順に並べる") {
            VStack(alignment: .leading, spacing: 8) {
                if let topic = engine.topic {
                    TopicRow(topic: topic)
                        .padding(.horizontal, 16)
                }
                List {
                    ForEach(Array(order.enumerated()), id: \.element.id) { index, fate in
                        HStack(spacing: 14) {
                            Text("\(index + 1)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(index == 0 ? Theme.primary : Theme.primaryLight))
                            KanjiTileView(char: fate.char, size: 48)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.inkDisabled)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        // 背景はコンテンツ側にのみ（listRowBackgroundだと余白まで塗られてカード間が詰まる）
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.card)
                                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.tileBorder, lineWidth: 1.5))
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    }
                    // システムのドラッグハンドルは使わず、カード長押しで並び替える
                    .onMove { from, to in
                        order.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .padding(.top, 16)
        } actions: {
            ChalkButton(title: "採点 完了") {
                session.update { $0.submitRanking(orderedFateIDs: order.map(\.id)) }
            }
        }
        .onAppear { order = session.engine.flatSurvivors }
    }
}
