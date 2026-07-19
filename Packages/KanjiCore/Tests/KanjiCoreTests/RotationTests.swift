import XCTest
@testable import KanjiCore

final class RotationTests: XCTestCase {

    func test_sequential_answererFollowsRegistrationOrder() throws {
        let players = makePlayers(4)
        let config = try GameConfig(players: players, rounds: 1, charsPerPlayer: 2, answererMode: .sequential)
        var e = GameEngine(config: config, topics: makeTopics(20), seed: 3)

        var order: [Player.ID] = []
        for _ in 0..<4 {
            order.append(e.answerer.id)
            e.runTurnAsGiveUp()
        }
        XCTAssertEqual(order, players.map { $0.id })
        XCTAssertEqual(e.phase, .finalResult)
    }

    func test_roundRobin_eachRoundIsFullPermutation_andDeterministic() throws {
        let players = makePlayers(4)
        let config = try GameConfig(players: players, rounds: 2, charsPerPlayer: 2, answererMode: .roundRobin)
        let seed: UInt64 = 42

        func collectAnswerers(_ e: inout GameEngine, count: Int) -> [Player.ID] {
            var out: [Player.ID] = []
            for _ in 0..<count {
                out.append(e.answerer.id)
                e.runTurnAsGiveUp()
            }
            return out
        }

        var e1 = GameEngine(config: config, topics: makeTopics(30), seed: seed)
        let r1 = collectAnswerers(&e1, count: 4)
        XCTAssertEqual(e1.phase, .roundResult)
        e1.proceedFromRoundResult()
        let r2 = collectAnswerers(&e1, count: 4)
        XCTAssertEqual(e1.phase, .finalResult)

        let all = Set(players.map { $0.id })
        XCTAssertEqual(Set(r1), all, "ラウンド1で全員が1回ずつ回答者になる")
        XCTAssertEqual(Set(r2), all, "ラウンド2で全員が1回ずつ回答者になる")

        // 決定性: 同じ seed の別インスタンスは同じ順序
        var e2 = GameEngine(config: config, topics: makeTopics(30), seed: seed)
        let r1b = collectAnswerers(&e2, count: 4)
        XCTAssertEqual(r1, r1b)
    }

    func test_fixed_alwaysSamePlayer_andTurnsPerRoundIsPMinus1() throws {
        let players = makePlayers(4)
        let fixedID = players[2].id
        let config = try GameConfig(players: players, rounds: 1, charsPerPlayer: 2, answererMode: .fixed(fixedID))
        var e = GameEngine(config: config, topics: makeTopics(20), seed: 5)

        XCTAssertEqual(e.turnsPerRound, 3)
        var order: [Player.ID] = []
        for _ in 0..<3 {
            order.append(e.answerer.id)
            e.runTurnAsGiveUp()
        }
        XCTAssertEqual(order, [fixedID, fixedID, fixedID])
        XCTAssertEqual(e.phase, .finalResult)
    }
}
