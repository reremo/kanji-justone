import Foundation

/// 決定的な擬似乱数生成器（SplitMix64）。seed から同じ列を再現できる。
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// 複数の値から決定的な派生 seed を作る。
func combinedSeed(_ a: UInt64, _ b: UInt64, _ c: UInt64) -> UInt64 {
    var rng = SplitMix64(seed: a &+ (b &* 0x9E37_79B9_7F4A_7C15) &+ (c &* 0xBF58_476D_1CE4_E5B9))
    return rng.next()
}

extension Array {
    /// seed から決定的に Fisher-Yates シャッフルした配列を返す。
    func deterministicShuffled(seed: UInt64) -> [Element] {
        var rng = SplitMix64(seed: seed)
        var arr = self
        var i = arr.count - 1
        while i > 0 {
            let j = Int(rng.next() % UInt64(i + 1))
            arr.swapAt(i, j)
            i -= 1
        }
        return arr
    }
}
