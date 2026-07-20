import XCTest
@testable import KanjiCore

final class StateMachineTests: XCTestCase {

    private func makeEngine(players: Int = 4, rounds: Int = 1, charsPerPlayer: Int = 2) throws -> GameEngine {
        let config = try GameConfig(players: makePlayers(players), rounds: rounds, charsPerPlayer: charsPerPlayer)
        return GameEngine(config: config, topics: makeTopics(20), seed: 11)
    }

    func test_happyPath_answererRevealToTurnResult() throws {
        var e = try makeEngine()
        XCTAssertEqual(e.phase, .answererReveal)
        e.proceedFromAnswererReveal()
        XCTAssertEqual(e.phase, .topicGate)
        e.confirmAnswererNotLooking()
        XCTAssertEqual(e.phase, .topicReveal)
        e.finishTopicViewing()
        XCTAssertEqual(e.phase, .hintHandoff)
        e.submitDistinctHints()
        XCTAssertEqual(e.phase, .hintConfirm)
        e.finishHintConfirm()
        XCTAssertEqual(e.phase, .answerHandoff)
        e.answererReceived()
        XCTAssertEqual(e.phase, .answerInput)
        e.submitAnswer("答え")
        XCTAssertEqual(e.phase, .judge)
        e.judgeCorrect()
        XCTAssertEqual(e.phase, .ranking)
        let ids = e.survivors.map { $0.id }
        e.submitRanking(orderedFateIDs: ids)
        XCTAssertEqual(e.phase, .turnResult(.correct))
    }

    func test_skipTopic_redrawsAndStaysTopicReveal() throws {
        var e = try makeEngine()
        e.proceedFromAnswererReveal()
        e.confirmAnswererNotLooking()
        XCTAssertEqual(e.phase, .topicReveal)
        let first = e.topic
        e.skipTopic()
        XCTAssertEqual(e.phase, .topicReveal)
        XCTAssertNotNil(e.topic)
        XCTAssertNotEqual(e.topic?.id, first?.id, "スキップでお題が引き直される")
    }

    func test_hintInputRepeatsForEachGiver() throws {
        var e = try makeEngine(players: 4)  // 出題者3人
        e.advanceToFirstHint()
        XCTAssertEqual(e.hintGivers.count, 3)

        e.confirmHintPerson()
        _ = e.submitHint(chars: ["山", "川"])
        XCTAssertEqual(e.phase, .hintHandoff)  // まだ2人残り
        e.confirmHintPerson()
        _ = e.submitHint(chars: ["風", "空"])
        XCTAssertEqual(e.phase, .hintHandoff)  // まだ1人残り
        e.confirmHintPerson()
        _ = e.submitHint(chars: ["海", "森"])
        XCTAssertEqual(e.phase, .hintConfirm)  // 全員完了
    }

    func test_currentHintGiverAdvances() throws {
        var e = try makeEngine(players: 4)
        e.advanceToFirstHint()
        let givers = e.hintGivers
        XCTAssertEqual(e.currentHintGiver, givers[0])
        e.confirmHintPerson()
        XCTAssertEqual(e.currentHintGiver, givers[0])
        _ = e.submitHint(chars: ["山", "川"])
        XCTAssertEqual(e.currentHintGiver, givers[1])
    }

    func test_manualDeleteToZeroSurvivors_wipeout() throws {
        // charsPerPlayer=1, P=3 → 出題者2人 → 生存2枚。両方手動削除で全滅
        var e = try makeEngine(players: 3, charsPerPlayer: 1)
        e.advanceToFirstHint()
        e.confirmHintPerson()
        _ = e.submitHint(chars: ["山"])
        e.confirmHintPerson()
        _ = e.submitHint(chars: ["川"])
        XCTAssertEqual(e.phase, .hintConfirm)
        XCTAssertEqual(e.survivors.count, 2)

        e.manuallyDelete(fateID: e.survivors.first { $0.char == "山" }!.id)
        XCTAssertEqual(e.phase, .hintConfirm)
        e.manuallyDelete(fateID: e.survivors.first { $0.char == "川" }!.id)
        XCTAssertEqual(e.phase, .turnResult(.wipeout))
    }

    func test_autoDedupZeroSurvivors_skipsHintConfirm_directWipeout() throws {
        var e = try makeEngine(players: 4)
        e.advanceToFirstHint()
        let subs: [[Character]] = [["山", "川"], ["山", "風"], ["川", "風"]]
        for chars in subs {
            e.confirmHintPerson()
            _ = e.submitHint(chars: chars)
        }
        // hintConfirm を経ずに wipeout
        XCTAssertEqual(e.phase, .turnResult(.wipeout))
    }

    func test_judgeWrong_returnsToAnswerInput_keepsAnswerText() throws {
        var e = try makeEngine(players: 4)
        e.advanceToFirstHint()
        e.submitDistinctHints()
        e.finishHintConfirm()
        e.answererReceived()
        e.submitAnswer("まちがい")
        e.judgeWrong()
        XCTAssertEqual(e.phase, .answerInput)
        XCTAssertEqual(e.answerText, "まちがい")
    }

    func test_judgeGiveUp_skipsRanking_toTurnResult() throws {
        var e = try makeEngine(players: 4)
        e.advanceToFirstHint()
        e.submitDistinctHints()
        e.finishHintConfirm()
        e.answererReceived()
        e.submitAnswer("答え")
        e.judgeGiveUp()
        XCTAssertEqual(e.phase, .turnResult(.giveUp))
        XCTAssertTrue(e.fates.allSatisfy { $0.rank == nil }, "ギブアップでは順位付けしない")
    }

    func test_finalTurn_branchesToRoundResultThenFinalResult() throws {
        // rounds=2, P=3 → 各ラウンド3ターン
        var e = try makeEngine(players: 3, rounds: 2)
        // ラウンド1の3ターンを消化
        for _ in 0..<3 { e.runTurnAsGiveUp() }
        XCTAssertEqual(e.phase, .roundResult)
        e.proceedFromRoundResult()
        XCTAssertEqual(e.phase, .answererReveal)
        XCTAssertEqual(e.roundNumber, 2)
        // ラウンド2の3ターンを消化
        for _ in 0..<3 { e.runTurnAsGiveUp() }
        XCTAssertEqual(e.phase, .finalResult)
    }

    func test_singleRound_finalTurnGoesDirectlyToFinalResult() throws {
        var e = try makeEngine(players: 3, rounds: 1)
        for _ in 0..<3 { e.runTurnAsGiveUp() }
        XCTAssertEqual(e.phase, .finalResult)
    }
}
