import Foundation
import XCTest
@testable import KanjiCore

/// テスト用の固定プレイヤー生成（id を安定させ、決定性を保つ）
func makePlayers(_ n: Int) -> [Player] {
    (0..<n).map { i in
        Player(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000\(String(format: "%02d", i))")!, name: "P\(i)")
    }
}

func makeTopics(_ n: Int) -> [Topic] {
    (0..<n).map { i in
        Topic(id: "t\(i)", text: "お題\(i)", furigana: "おだい\(i)", difficulty: .normal)
    }
}

/// 出題者インデックスごとに割り当てる、被らない漢字プール
let kanjiPool: [Character] = ["山", "川", "風", "空", "海", "森", "林", "火", "水", "木", "金", "土", "日", "月", "星", "雲", "雨", "雪"]

extension GameEngine {
    /// answererReveal から hintHandoff(1人目) まで進める
    mutating func advanceToFirstHint() {
        proceedFromAnswererReveal()
        confirmAnswererNotLooking()
        finishTopicViewing()
    }

    /// 各出題者に被らない漢字を提出させる（charsPerPlayer=2 前提のプール使用）
    mutating func submitDistinctHints() {
        let count = hintGivers.count
        for i in 0..<count {
            confirmHintPerson()
            let chars = Array(kanjiPool[(2 * i)..<(2 * i + config.charsPerPlayer)])
            _ = submitHint(chars: chars)
        }
    }

    /// 1ターンをギブアップで完走し、次の状態まで進める
    mutating func runTurnAsGiveUp() {
        advanceToFirstHint()
        submitDistinctHints()
        finishHintConfirm()
        answererReceived()
        submitAnswer("x")
        judgeGiveUp()
        proceedFromTurnResult()
    }
}
