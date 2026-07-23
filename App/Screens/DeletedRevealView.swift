import SwiftUI
import KanjiCore

/// S11.5 消えた漢字の発表（重複・没だけを公開）。ヘッダーなしのシンプルな全画面リビール。
struct DeletedRevealView: View {
    @Environment(GameSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onNext: () -> Void

    var body: some View {
        let deleted = session.engine.flatDeleted
        let size = tileSize(deleted.count)
        let rows = chunk(deleted, perRow: perRow(deleted.count))
        VStack(spacing: 0) {
            Spacer()

            Text("消えた漢字")
                .font(Theme.font(22))
                .foregroundStyle(Theme.chalk)
            Text("重複・違反で消えたヒント")
                .font(Theme.font(13))
                .foregroundStyle(Theme.chalkFaded)
                .padding(.top, 6)

            VStack(spacing: 14) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 14) {
                        ForEach(row) { fate in
                            StampingTile(char: fate.char,
                                         manual: fate.state == .manualDeleted,
                                         size: size,
                                         delay: delay(for: fate.id, in: deleted))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)

            Spacer()

            ChalkButton(title: "次へ", action: onNext)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.board.ignoresSafeArea())
    }

    // MARK: - 枚数に応じた折り返し・縮小

    /// 1行あたりの枚数（枚数が多いほど詰める）
    private func perRow(_ count: Int) -> Int {
        switch count {
        case ...3: return count
        case ...6: return 3
        case ...12: return 4
        default: return 5
        }
    }

    /// 札の大きさ（枚数が多いほど小さく）
    private func tileSize(_ count: Int) -> CGFloat {
        switch count {
        case ...3: return 92
        case ...6: return 78
        case ...12: return 62
        default: return 50
        }
    }

    private func chunk(_ items: [CharFate], perRow: Int) -> [[CharFate]] {
        guard perRow > 0 else { return [items] }
        return stride(from: 0, to: items.count, by: perRow).map {
            Array(items[$0..<min($0 + perRow, items.count)])
        }
    }

    private func delay(for id: UUID, in items: [CharFate]) -> Double {
        (items.firstIndex { $0.id == id }.map(Double.init) ?? 0) * 0.18
    }
}

/// 朱印で隠れた漢字 → スタンプが外れて（浮き上がって消えて）漢字が現れる札
private struct StampingTile: View {
    let char: Character
    let manual: Bool
    let size: CGFloat
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tileIn = false
    @State private var lifted = false      // スタンプが外れたか

    var body: some View {
        ZStack {
            KanjiTileView(char: char, size: size)
            SealStamp(lines: manual ? ["没"] : ["重", "複"], size: size, angle: manual ? -8 : 8)
                .scaleEffect(lifted ? 1.5 : 1)
                .opacity(lifted ? 0 : 1)
                .offset(y: lifted ? -size * 0.35 : 0)
                .rotationEffect(.degrees(lifted ? (manual ? -18 : 16) : 0))
        }
        .frame(width: size, height: size)
        .scaleEffect(tileIn ? 1 : 0.85)
        .opacity(tileIn ? 1 : 0)
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        if reduceMotion {
            tileIn = true; lifted = true
            return
        }
        withAnimation(.easeOut(duration: 0.2)) { tileIn = true }
        Task {
            // まず漢字＋スタンプが見え、しっかり間を置いてからスタンプが外れて漢字が現れる
            try? await Task.sleep(for: .seconds(delay + 0.9))
            Haptics.light()
            withAnimation(.easeOut(duration: 0.4)) { lifted = true }
        }
    }
}
