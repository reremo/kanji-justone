import SwiftUI
import KanjiCore

/// S12 役に立った順に並べる（回答者による採点）
struct RankingView: View {
    @Environment(GameSession.self) private var session
    @State private var order: [CharFate] = []

    var body: some View {
        let engine = session.engine
        ChalkScreen(progress: session.progressLine, title: "役に立った順に並べる") {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(engine.answerer.name)さんが「役に立った順」に並べます（ドラッグで入れかえ）")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkFaded)
                    .padding(.horizontal, 16)
                List {
                    ForEach(Array(order.enumerated()), id: \.element.id) { index, fate in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(index == 0 ? Theme.primary : Theme.primaryLight))
                            KanjiTileView(char: fate.char, size: 44)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.card)
                                .padding(.vertical, 3)
                        )
                        .listRowSeparator(.hidden)
                    }
                    .onMove { from, to in
                        order.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
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
