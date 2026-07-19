import XCTest
@testable import KanjiCore

/// confirmGroups / flatSurvivors の決定性・整合性を検証する。
final class PresentationTests: XCTestCase {

    private func engineAtHintConfirm(seed: UInt64) throws -> GameEngine {
        let config = try GameConfig(players: makePlayers(4), rounds: 1, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(20), seed: seed)
        e.advanceToFirstHint()
        let subs: [[Character]] = [["山", "川"], ["風", "空"], ["海", "森"]]
        for chars in subs {
            e.confirmHintPerson()
            _ = e.submitHint(chars: chars)
        }
        XCTAssertEqual(e.phase, .hintConfirm)
        return e
    }

    func test_confirmGroups_groupsBySameOwner_containsAllSurvivors() throws {
        let e = try engineAtHintConfirm(seed: 1)
        let groups = e.confirmGroups
        // 出題者3人 → 3グループ、各2文字
        XCTAssertEqual(groups.count, 3)
        for group in groups {
            let owners = Set(group.map { $0.ownerID })
            XCTAssertEqual(owners.count, 1, "1グループは同一人物のみ")
            XCTAssertEqual(group.count, 2)
        }
        let flat = groups.flatMap { $0 }.map { $0.char }
        XCTAssertEqual(flat.sorted(), ["山", "川", "風", "空", "海", "森"].sorted())
    }

    func test_confirmGroups_isDeterministicForSameState() throws {
        let e = try engineAtHintConfirm(seed: 123)
        let a = e.confirmGroups.map { $0.map { $0.char } }
        let b = e.confirmGroups.map { $0.map { $0.char } }
        XCTAssertEqual(a, b, "同一状態では同じシャッフル結果")

        // 別インスタンス・同一 seed でも一致
        let e2 = try engineAtHintConfirm(seed: 123)
        let c = e2.confirmGroups.map { $0.map { $0.char } }
        XCTAssertEqual(a, c)
    }

    func test_flatSurvivors_containsAllSurvivors_deterministic() throws {
        let e = try engineAtHintConfirm(seed: 77)
        let flat = e.flatSurvivors
        XCTAssertEqual(flat.count, 6)
        XCTAssertEqual(flat.map { $0.char }.sorted(), ["山", "川", "風", "空", "海", "森"].sorted())
        // 決定性
        XCTAssertEqual(e.flatSurvivors.map { $0.id }, e.flatSurvivors.map { $0.id })
        let e2 = try engineAtHintConfirm(seed: 77)
        XCTAssertEqual(e.flatSurvivors.map { $0.char }, e2.flatSurvivors.map { $0.char })
    }

    func test_flatSurvivors_excludesDeletedChars() throws {
        var e = try engineAtHintConfirm(seed: 5)
        let target = e.survivors.first { $0.char == "山" }!.id
        e.manuallyDelete(fateID: target)
        XCTAssertFalse(e.flatSurvivors.contains { $0.char == "山" })
        XCTAssertEqual(e.flatSurvivors.count, 5)
    }
}

/// お題抽選の挙動を検証する。
final class TopicTests: XCTestCase {

    func test_topicIsChosenAtStart() throws {
        let config = try GameConfig(players: makePlayers(4), rounds: 1)
        let e = GameEngine(config: config, topics: makeTopics(10), seed: 1)
        XCTAssertNotNil(e.topic)
    }

    func test_topicsAreDrawnWithoutRepetitionWithinPool() throws {
        // rounds=2, P=3 → 6ターン。10問プールなので全ターン重複なし
        let config = try GameConfig(players: makePlayers(3), rounds: 2, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 4)
        var seen: [String] = []
        for round in 0..<2 {
            for _ in 0..<3 {
                seen.append(e.topic!.id)
                e.runTurnAsGiveUp()
            }
            if round == 0 { e.proceedFromRoundResult() }
        }
        XCTAssertEqual(Set(seen).count, seen.count, "プール内では重複なく抽選される")
    }

    func test_determinism_sameSeedSameTopicSequence() throws {
        let config = try GameConfig(players: makePlayers(4), rounds: 1)
        let e1 = GameEngine(config: config, topics: makeTopics(10), seed: 555)
        let e2 = GameEngine(config: config, topics: makeTopics(10), seed: 555)
        XCTAssertEqual(e1.topic?.id, e2.topic?.id)
    }
}
