import XCTest
@testable import KanjiCore

final class HintRulesTests: XCTestCase {

    func test_rejectsNonKanji_hiragana() {
        XCTAssertEqual(HintRules.validate(chars: ["あ", "山"], expectedCount: 2), .notKanji("あ"))
    }

    func test_rejectsNonKanji_katakana() {
        XCTAssertEqual(HintRules.validate(chars: ["ア", "山"], expectedCount: 2), .notKanji("ア"))
    }

    func test_rejectsNonKanji_alphanumeric() {
        XCTAssertEqual(HintRules.validate(chars: ["A", "山"], expectedCount: 2), .notKanji("A"))
        XCTAssertEqual(HintRules.validate(chars: ["1", "山"], expectedCount: 2), .notKanji("1"))
    }

    func test_rejectsIterationMark_andSpecialSymbols() {
        // 「々」(U+3005)・「〆」(U+3006) は漢字ブロック外 → 不可
        XCTAssertEqual(HintRules.validate(chars: ["々", "山"], expectedCount: 2), .notKanji("々"))
        XCTAssertEqual(HintRules.validate(chars: ["〆", "山"], expectedCount: 2), .notKanji("〆"))
    }

    func test_rejectsDuplicateOwnChar() {
        XCTAssertEqual(HintRules.validate(chars: ["山", "山"], expectedCount: 2), .duplicateOwnChar("山"))
    }

    func test_rejectsWrongLength() {
        XCTAssertEqual(HintRules.validate(chars: ["山"], expectedCount: 2), .wrongLength)
        XCTAssertEqual(HintRules.validate(chars: ["山", "川", "風"], expectedCount: 2), .wrongLength)
    }

    func test_acceptsValidKanji() {
        XCTAssertNil(HintRules.validate(chars: ["山", "川"], expectedCount: 2))
    }

    func test_acceptsExtensionAKanji() {
        // U+3400（拡張A先頭）は許可
        XCTAssertNil(HintRules.validate(chars: ["\u{3400}", "山"], expectedCount: 2))
    }

    func test_isKanji_boundaries() {
        XCTAssertTrue(HintRules.isKanji("\u{4E00}"))   // CJK統合漢字 先頭
        XCTAssertTrue(HintRules.isKanji("\u{9FFF}"))   // CJK統合漢字 末尾
        XCTAssertTrue(HintRules.isKanji("\u{3400}"))   // 拡張A 先頭
        XCTAssertTrue(HintRules.isKanji("\u{4DBF}"))   // 拡張A 末尾
        XCTAssertFalse(HintRules.isKanji("\u{3005}"))  // 々
        XCTAssertFalse(HintRules.isKanji("A"))
    }
}

final class GameConfigTests: XCTestCase {

    func test_rejectsTooFewPlayers() {
        XCTAssertThrowsError(try GameConfig(players: makePlayers(2), rounds: 1)) { error in
            XCTAssertEqual(error as? GameConfigError, .invalidPlayerCount)
        }
    }

    func test_rejectsTooManyPlayers() {
        XCTAssertThrowsError(try GameConfig(players: makePlayers(9), rounds: 1)) { error in
            XCTAssertEqual(error as? GameConfigError, .invalidPlayerCount)
        }
    }

    func test_acceptsPlayerCountBoundaries() {
        XCTAssertNoThrow(try GameConfig(players: makePlayers(3), rounds: 1))
        XCTAssertNoThrow(try GameConfig(players: makePlayers(8), rounds: 1))
    }

    func test_rejectsInvalidRounds() {
        XCTAssertThrowsError(try GameConfig(players: makePlayers(4), rounds: 0)) { error in
            XCTAssertEqual(error as? GameConfigError, .invalidRounds)
        }
    }

    func test_rejectsInvalidCharsPerPlayer() {
        XCTAssertThrowsError(try GameConfig(players: makePlayers(4), rounds: 1, charsPerPlayer: 0)) { error in
            XCTAssertEqual(error as? GameConfigError, .invalidCharsPerPlayer)
        }
    }

    func test_rejectsFixedAnswererNotInPlayers() {
        let stranger = UUID()
        XCTAssertThrowsError(
            try GameConfig(players: makePlayers(4), rounds: 1, answererMode: .fixed(stranger))
        ) { error in
            XCTAssertEqual(error as? GameConfigError, .fixedAnswererNotInPlayers)
        }
    }

    func test_acceptsFixedAnswererInPlayers() {
        let players = makePlayers(4)
        XCTAssertNoThrow(try GameConfig(players: players, rounds: 1, answererMode: .fixed(players[1].id)))
    }
}
