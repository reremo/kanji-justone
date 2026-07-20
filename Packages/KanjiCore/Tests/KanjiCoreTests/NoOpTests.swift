import XCTest
@testable import KanjiCore

/// 現在フェーズで不正なイベントは no-op（状態を変えない）であることを検証する。
final class NoOpTests: XCTestCase {

    private func makeEngine() throws -> GameEngine {
        let config = try GameConfig(players: makePlayers(4), rounds: 1, charsPerPlayer: 2)
        return GameEngine(config: config, topics: makeTopics(20), seed: 99)
    }

    func test_submitHint_inTopicGate_isNoOp() throws {
        var e = try makeEngine()
        e.proceedFromAnswererReveal()  // topicGate
        let before = e.phase
        let result = e.submitHint(chars: ["山", "川"])
        XCTAssertNil(result)
        XCTAssertEqual(e.phase, before)
        XCTAssertTrue(e.fates.isEmpty)
    }

    func test_confirmAnswererNotLooking_inAnswererReveal_isNoOp() throws {
        var e = try makeEngine()
        e.confirmAnswererNotLooking()  // まだ answererReveal
        XCTAssertEqual(e.phase, .answererReveal)
    }

    func test_skipTopic_outsideTopicReveal_isNoOp() throws {
        var e = try makeEngine()
        let before = e.topic
        e.skipTopic()  // answererReveal 中
        XCTAssertEqual(e.phase, .answererReveal)
        XCTAssertEqual(e.topic?.id, before?.id)
    }

    func test_judgeCorrect_inAnswerInput_isNoOp() throws {
        var e = try makeEngine()
        e.advanceToFirstHint()
        e.submitDistinctHints()
        e.finishHintConfirm()
        e.answererReceived()  // answerInput
        e.judgeCorrect()      // judge ではないので無視
        XCTAssertEqual(e.phase, .answerInput)
    }

    func test_proceedFromRoundResult_whenNotRoundResult_isNoOp() throws {
        var e = try makeEngine()
        e.proceedFromRoundResult()
        XCTAssertEqual(e.phase, .answererReveal)
        XCTAssertEqual(e.roundNumber, 1)
    }

    func test_manuallyDelete_outsideHintConfirm_isNoOp() throws {
        var e = try makeEngine()
        e.advanceToFirstHint()
        e.confirmHintPerson()
        _ = e.submitHint(chars: ["山", "川"])
        // まだ hintHandoff（残り出題者あり）。ここでの手動削除は無視
        let survivedBefore = e.survivors.count
        if let anyID = e.fates.first?.id {
            e.manuallyDelete(fateID: anyID)
        }
        XCTAssertEqual(e.survivors.count, survivedBefore)
    }

    func test_submitInvalidHint_returnsError_andDoesNotAdvance() throws {
        var e = try makeEngine()
        e.advanceToFirstHint()
        e.confirmHintPerson()
        let result = e.submitHint(chars: ["山"])  // 文字数不足
        XCTAssertEqual(result, .wrongLength)
        XCTAssertEqual(e.phase, .hintInput)
        XCTAssertTrue(e.fates.isEmpty)
        XCTAssertEqual(e.currentHintGiver, e.hintGivers[0])
    }
}
