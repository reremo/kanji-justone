import Foundation
import Observation
import KanjiCore

/// UI が購読する単一ストア。ドメインは KanjiCore.GameEngine に委譲する。
@Observable
final class GameSession {
    private(set) var engine: GameEngine
    let topics: [Topic]

    init() {
        let topics = Self.loadTopics()
        self.topics = topics
        self.engine = Self.makeEngine(topics: topics)
    }

    func restart() {
        engine = Self.makeEngine(topics: topics)
    }

    /// エンジンへの変更操作（@Observable の変更通知を確実に発火させる窓口）
    func update(_ mutate: (inout GameEngine) -> Void) {
        mutate(&engine)
    }

    var progressLine: String {
        "ラウンド \(engine.roundNumber)/\(engine.config.rounds) ・ \(engine.turnNumber)/\(engine.turnsPerRound)人目 ・ 回答者: \(engine.answerer.name)"
    }

    // MARK: - Setup

    private static func makeEngine(topics: [Topic]) -> GameEngine {
        // デバッグ用固定メンバー・固定設定（プレイヤー選択/設定画面は後続機能）
        let players = ["ゆうき", "あかね", "けんた", "みさき"].map { Player(name: $0) }
        let config = try! GameConfig(players: players, rounds: 2, charsPerPlayer: 2, answererMode: .sequential)
        return GameEngine(config: config, topics: topics, seed: UInt64(Date().timeIntervalSince1970))
    }

    private static func loadTopics() -> [Topic] {
        struct TopicFile: Decodable {
            let schemaVersion: Int
            let topics: [Topic]
        }
        guard let url = Bundle.main.url(forResource: "topics-dev", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(TopicFile.self, from: data) else {
            fatalError("topics-dev.json をバンドルから読み込めませんでした")
        }
        return file.topics
    }
}
