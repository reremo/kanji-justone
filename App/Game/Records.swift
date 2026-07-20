import Foundation
import KanjiCore

/// 1文字ぶんの記録（将来のAI分析に備えた生ログ。集計値に潰さない）
struct HintRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var playerName: String
    var char: String
    var state: String        // survived / autoDeleted / manualDeleted
    var rank: Int?

    var isDeleted: Bool { state != "survived" }
}

struct TurnRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var topicText: String
    var topicFurigana: String
    var answererName: String
    var outcome: String      // correct / giveUp / wipeout
    var hints: [HintRecord]
    var scores: [String: Int] // playerName: 得点
}

struct GameRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var playerNames: [String]
    var rounds: Int
    var turns: [TurnRecord]
    var totals: [String: Int] // playerName: 合計点
    var schemaVersion = 1

    var winnerName: String? {
        totals.max { $0.value < $1.value }?.key
    }
}

extension TurnRecord {
    init(engine: GameEngine, outcome: TurnOutcome) {
        let name: (Player.ID) -> String = { id in
            engine.config.players.first { $0.id == id }?.name ?? "?"
        }
        self.init(
            topicText: engine.topic?.text ?? "",
            topicFurigana: engine.topic?.furigana ?? "",
            answererName: engine.answerer.name,
            outcome: {
                switch outcome {
                case .correct: "correct"
                case .giveUp: "giveUp"
                case .wipeout: "wipeout"
                }
            }(),
            hints: engine.fates.map { fate in
                HintRecord(
                    playerName: name(fate.ownerID),
                    char: String(fate.char),
                    state: {
                        switch fate.state {
                        case .survived: "survived"
                        case .autoDeleted: "autoDeleted"
                        case .manualDeleted: "manualDeleted"
                        }
                    }(),
                    rank: fate.rank
                )
            },
            scores: Dictionary(uniqueKeysWithValues: engine.lastTurnScores.map { (name($0.key), $0.value) })
        )
    }
}
