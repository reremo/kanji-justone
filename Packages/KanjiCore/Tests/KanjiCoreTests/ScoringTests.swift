import XCTest
@testable import KanjiCore

final class ScoringTests: XCTestCase {

    /// submissions を提出 → hintConfirm。deleteChars を手動削除 → ranking へ進め、
    /// rankOrder（役に立った順の漢字列）で採点まで実行する。
    private func playToCorrect(
        players: Int,
        charsPerPlayer: Int = 2,
        submissions: [[Character]],
        deleteChars: [Character] = [],
        rankOrder: [Character]
    ) throws -> GameEngine {
        let config = try GameConfig(players: makePlayers(players), rounds: 1, charsPerPlayer: charsPerPlayer)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 7)
        e.advanceToFirstHint()
        for chars in submissions {
            e.confirmHintPerson()
            _ = e.submitHint(chars: chars)
        }
        XCTAssertEqual(e.phase, .hintConfirm, "手動削除前に hintConfirm へ到達しているはず")
        for c in deleteChars {
            let id = e.survivors.first { $0.char == c }!.id
            e.manuallyDelete(fateID: id)
        }
        e.finishHintConfirm()
        e.answererReceived()
        e.submitAnswer("答え")
        e.judgeCorrect()
        XCTAssertEqual(e.phase, .ranking)
        let ids = rankOrder.map { c in e.survivors.first { $0.char == c }!.id }
        e.submitRanking(orderedFateIDs: ids)
        XCTAssertEqual(e.phase, .turnResult(.correct))
        return e
    }

    func test_correct_noDeletions() throws {
        // P=4, 出題者3人。削除0。回答者+4、出題者は最高順位順に +4/+3/+2
        let players = makePlayers(4)
        let config = try GameConfig(players: players, rounds: 1, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 7)
        e.advanceToFirstHint()
        // G1=P1[山,川], G2=P2[風,空], G3=P3[海,森]
        let subs: [[Character]] = [["山", "川"], ["風", "空"], ["海", "森"]]
        for chars in subs {
            e.confirmHintPerson()
            _ = e.submitHint(chars: chars)
        }
        e.finishHintConfirm()
        e.answererReceived()
        e.submitAnswer("答え")
        e.judgeCorrect()
        // ランク: 山(G1)=1, 風(G2)=2, 海(G3)=3, 川=4, 空=5, 森=6 → 各出題者最高順位 G1=1,G2=2,G3=3
        let order: [Character] = ["山", "風", "海", "川", "空", "森"]
        let ids = order.map { c in e.survivors.first { $0.char == c }!.id }
        e.submitRanking(orderedFateIDs: ids)

        XCTAssertEqual(e.lastTurnScores[players[0].id], 4)  // 回答者 +4 + 削除0
        XCTAssertEqual(e.lastTurnScores[players[1].id], 4)  // G1 1位
        XCTAssertEqual(e.lastTurnScores[players[2].id], 3)  // G2 2位
        XCTAssertEqual(e.lastTurnScores[players[3].id], 2)  // G3 3位
    }

    func test_correct_withDeletions_answererBonus() throws {
        // 自動2（山×2）+ 手動1（川）= 削除3。回答者 = 4 + 3 = 7
        let players = makePlayers(4)
        let e = try playToCorrect(
            players: 4,
            submissions: [["山", "川"], ["山", "風"], ["空", "海"]],
            deleteChars: ["川"],
            rankOrder: ["風", "空", "海"]
        )
        XCTAssertEqual(e.deletedCount, 3)
        XCTAssertEqual(e.lastTurnScores[players[0].id], 7)  // 回答者 +4 + 削除3
    }

    func test_bestRankComparison_singleTopBeatsTwoLowerCards() throws {
        // P=3, 出題者2人。G_A(P1) は削除で山1枚のみ(rank1)、G_B(P2) は風(rank2),空(rank3)
        let players = makePlayers(3)
        let e = try playToCorrect(
            players: 3,
            submissions: [["山", "川"], ["風", "空"]],
            deleteChars: ["川"],           // G_A の川を削除 → G_A は山のみ
            rankOrder: ["山", "風", "空"]  // 山=1, 風=2, 空=3
        )
        let a = e.lastTurnScores[players[1].id]!  // G_A
        let b = e.lastTurnScores[players[2].id]!  // G_B
        XCTAssertGreaterThan(a, b)
        XCTAssertEqual(a, 3)  // 1位 +P(=3)
        XCTAssertEqual(b, 2)  // 2位 +P-1
    }

    func test_zeroSurvivorGiver_getsZero_othersRankedFromP() throws {
        // P=4, 出題者3人。G1(P1)[山,川] は全て他と重複し全滅、G2(P2)[山,空], G3(P3)[川,海]
        // 山=G1,G2 / 川=G1,G3 → G1 は生存0、G2は空、G3は海が生存
        let players = makePlayers(4)
        let e = try playToCorrect(
            players: 4,
            submissions: [["山", "川"], ["山", "空"], ["川", "海"]],
            rankOrder: ["空", "海"]  // 空(G2)=1, 海(G3)=2
        )
        XCTAssertEqual(e.lastTurnScores[players[1].id], 0)  // G1 生存0 → 0点
        XCTAssertEqual(e.lastTurnScores[players[2].id], 4)  // G2 1位 +P
        XCTAssertEqual(e.lastTurnScores[players[3].id], 3)  // G3 2位
        XCTAssertEqual(e.deletedCount, 4)
        XCTAssertEqual(e.lastTurnScores[players[0].id], 4 + 4)  // 回答者 +P + 削除4
    }

    func test_giveUp_allZero() throws {
        let players = makePlayers(4)
        let config = try GameConfig(players: players, rounds: 1, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 7)
        e.advanceToFirstHint()
        e.submitDistinctHints()
        e.finishHintConfirm()
        e.answererReceived()
        e.submitAnswer("答え")
        e.judgeGiveUp()
        XCTAssertEqual(e.phase, .turnResult(.giveUp))
        for p in players {
            XCTAssertEqual(e.lastTurnScores[p.id], 0)
            XCTAssertEqual(e.totalScores[p.id], 0)
        }
    }

    func test_wipeout_allZero() throws {
        let players = makePlayers(4)
        let config = try GameConfig(players: players, rounds: 1, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 7)
        e.advanceToFirstHint()
        let subs: [[Character]] = [["山", "川"], ["山", "風"], ["川", "風"]]
        for chars in subs {
            e.confirmHintPerson()
            _ = e.submitHint(chars: chars)
        }
        XCTAssertEqual(e.phase, .turnResult(.wipeout))
        for p in players {
            XCTAssertEqual(e.lastTurnScores[p.id], 0)
            XCTAssertEqual(e.totalScores[p.id], 0)
        }
    }

    func test_totalScoresAccumulateAcrossTurns() throws {
        // 2ターン正解で累計が加算されることを確認（回答者が毎ターン変わる sequential）
        let players = makePlayers(4)
        let config = try GameConfig(players: players, rounds: 1, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 7)

        func playCorrectTurn() {
            e.advanceToFirstHint()
            let subs: [[Character]] = [["山", "川"], ["風", "空"], ["海", "森"]]
        for chars in subs {
                e.confirmHintPerson()
                _ = e.submitHint(chars: chars)
            }
            e.finishHintConfirm()
            e.answererReceived()
            e.submitAnswer("答え")
            e.judgeCorrect()
            let order: [Character] = ["山", "風", "海", "川", "空", "森"]
            let ids = order.map { c in e.survivors.first { $0.char == c }!.id }
            e.submitRanking(orderedFateIDs: ids)
        }

        playCorrectTurn()  // 回答者 P0 = +4
        let afterTurn1 = e.totalScores[players[0].id]!
        XCTAssertEqual(afterTurn1, 4)
        e.proceedFromTurnResult()  // 次ターン、回答者 P1
        playCorrectTurn()          // このターンは P0 が出題者として得点
        XCTAssertGreaterThanOrEqual(e.totalScores[players[0].id]!, afterTurn1)
    }
}
