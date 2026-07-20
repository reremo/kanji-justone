import XCTest
@testable import KanjiCore

final class AutoDedupTests: XCTestCase {

    private func engineAfterSubmissions(players: Int, submissions: [[Character]]) throws -> GameEngine {
        let config = try GameConfig(players: makePlayers(players), rounds: 1, charsPerPlayer: 2)
        var e = GameEngine(config: config, topics: makeTopics(10), seed: 1)
        e.advanceToFirstHint()
        for chars in submissions {
            e.confirmHintPerson()
            _ = e.submitHint(chars: chars)
        }
        return e
    }

    func test_twoPlayersSameChar_bothAutoDeleted_othersSurvive() throws {
        // P=4 → 出題者3人
        let e = try engineAfterSubmissions(players: 4, submissions: [
            ["山", "川"],
            ["山", "風"],
            ["空", "海"],
        ])
        let deleted = e.fates.filter { $0.state == .autoDeleted }.map { $0.char }
        XCTAssertEqual(deleted.sorted(), ["山", "山"].sorted())
        XCTAssertEqual(e.survivors.map { $0.char }.sorted(), ["海", "川", "空", "風"].sorted())
    }

    func test_threePlayersSameChar_allThreeDeleted() throws {
        let e = try engineAfterSubmissions(players: 4, submissions: [
            ["山", "川"],
            ["山", "風"],
            ["山", "海"],
        ])
        let deleted = e.fates.filter { $0.state == .autoDeleted }.map { $0.char }
        XCTAssertEqual(deleted.filter { $0 == "山" }.count, 3)
        XCTAssertEqual(e.survivors.map { $0.char }.sorted(), ["海", "川", "風"].sorted())
    }

    func test_noDuplicates_allSurvive() throws {
        let e = try engineAfterSubmissions(players: 4, submissions: [
            ["山", "川"],
            ["風", "空"],
            ["海", "森"],
        ])
        XCTAssertEqual(e.survivors.count, 6)
        XCTAssertTrue(e.fates.allSatisfy { $0.state == .survived })
    }

    func test_allCharsDuplicated_zeroSurvivors_triggersWipeout() throws {
        // 山=G1,G2 / 川=G1,G3 / 風=G2,G3 → 全て重複
        let e = try engineAfterSubmissions(players: 4, submissions: [
            ["山", "川"],
            ["山", "風"],
            ["川", "風"],
        ])
        XCTAssertTrue(e.survivors.isEmpty)
        XCTAssertEqual(e.phase, .turnResult(.wipeout))
    }
}
