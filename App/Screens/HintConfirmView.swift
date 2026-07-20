import SwiftUI
import KanjiCore

/// S09 ヒントを確認（匿名グルーピング・消えた枠・全員一致の手動削除）
struct HintConfirmView: View {
    @Environment(GameSession.self) private var session
    @State private var selectedFateID: UUID?

    var body: some View {
        let engine = session.engine
        ChalkScreen(progress: session.progressLine, title: "ヒントを確認") {
            VStack(alignment: .leading, spacing: 16) {
                if let topic = engine.topic {
                    TopicRow(topic: topic)
                }
                Text("生き残った漢字です。同じ枠の中は同じ人が出した文字（順番はシャッフル済み）")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.chalkFaded)
                    .fixedSize(horizontal: false, vertical: true)
                FlowLayoutGroups(groups: engine.confirmGroups, fates: engine.fates, selectedFateID: $selectedFateID)
                Text("赤枠＝削除候補（タップで選択）。違反は全員一致で削除できます")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.chalkWarn)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        } actions: {
            ChalkButton(title: "全員が同意したら削除", style: .warnOutline, enabled: selectedFateID != nil) {
                if let id = selectedFateID {
                    session.update { $0.manuallyDelete(fateID: id) }
                    selectedFateID = nil
                }
            }
            ChalkButton(title: "確認完了 — 回答へ進む") {
                session.update { $0.finishHintConfirm() }
            }
        }
    }
}

/// グループ（人物単位・匿名）を折り返しで並べる
private struct FlowLayoutGroups: View {
    let groups: [[CharFate]]
    let fates: [CharFate]
    @Binding var selectedFateID: UUID?

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 150), alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                groupBox {
                    ForEach(group) { fate in
                        KanjiTileView(char: fate.char, selected: selectedFateID == fate.id)
                            .onTapGesture {
                                selectedFateID = (selectedFateID == fate.id) ? nil : fate.id
                            }
                    }
                    ForEach(0..<ghostCount(for: group), id: \.self) { _ in
                        AnimatedGhostSlot()
                    }
                }
            }
            // 全文字が消えた出題者の分も「消えた枠」だけのグループとして見せる（匿名のまま何文字消えたかを保証）
            ForEach(Array(wipedOwnerGhostCounts.enumerated()), id: \.offset) { _, count in
                groupBox {
                    ForEach(0..<count, id: \.self) { _ in
                        AnimatedGhostSlot()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func groupBox(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 8) { content() }
            .padding(8)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.tileBorder, lineWidth: 2))
    }

    private func ghostCount(for group: [CharFate]) -> Int {
        guard let owner = group.first?.ownerID else { return 0 }
        return fates.filter { $0.ownerID == owner && $0.state != .survived }.count
    }

    /// 生存文字が1枚もないオーナーごとの削除枚数（グループ順は fates 由来で固定）
    private var wipedOwnerGhostCounts: [Int] {
        let survivorOwners = Set(fates.filter { $0.state == .survived }.map(\.ownerID))
        var counts: [UUID: Int] = [:]
        for fate in fates where !survivorOwners.contains(fate.ownerID) {
            counts[fate.ownerID, default: 0] += 1
        }
        return counts.values.sorted()
    }
}

/// 「消えた」感を出すため、出現時にへこむようなスプリングで現れる消えた枠
private struct AnimatedGhostSlot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        GhostSlot()
            .scaleEffect(shown || reduceMotion ? 1 : 0.3)
            .opacity(shown || reduceMotion ? 1 : 0)
            .onAppear {
                withAnimation(.spring(duration: 0.5, bounce: 0.45).delay(0.25)) {
                    shown = true
                }
            }
    }
}

