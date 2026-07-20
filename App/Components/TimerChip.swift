import SwiftUI

/// フェーズの残り時間表示。強制遷移はせず、時間切れは表示で知らせるだけ（要件準拠）
struct TimerChip: View {
    let duration: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        TimelineView(.periodic(from: start, by: 0.5)) { context in
            let remaining = max(0, duration - context.date.timeIntervalSince(start))
            let seconds = Int(remaining.rounded(.up))
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 15))
                Text(remaining <= 0 ? "時間切れ！" : String(format: "%d:%02d", seconds / 60, seconds % 60))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(color(for: remaining))
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(Theme.card)
                    .shadow(color: Theme.tileShadow, radius: 0, x: 0, y: 2)
            )
            .scaleEffect(pulse(for: remaining, date: context.date) ? 1.08 : 1)
            .animation(.easeInOut(duration: 0.25), value: pulse(for: remaining, date: context.date))
        }
    }

    private func color(for remaining: TimeInterval) -> Color {
        if remaining <= 5 { return Theme.error }
        if remaining <= 10 { return Color(hex: 0xB8860B) }  // 警告（白地上で読める濃い黄土）
        return Theme.ink
    }

    private func pulse(for remaining: TimeInterval, date: Date) -> Bool {
        guard !reduceMotion, remaining > 0, remaining <= 5 else { return false }
        return Int(date.timeIntervalSince(start) * 2) % 2 == 0
    }
}
