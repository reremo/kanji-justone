import Foundation
import Observation
import KanjiCore

/// ゲーム進行中の単一ストア。ドメインは KanjiCore.GameEngine に委譲する。
@Observable
final class GameSession {
    private(set) var engine: GameEngine

    /// ターン確定時（turnResult 遷移時）の記録フック
    var onTurnFinished: ((GameEngine, TurnOutcome) -> Void)?
    /// 全ラウンド終了時（finalResult 遷移時）の記録フック
    var onGameFinished: ((GameEngine) -> Void)?

    init(config: GameConfig, topics: [Topic]) {
        engine = GameEngine(config: config, topics: topics, seed: UInt64.random(in: .min ... .max))
    }

    /// エンジンへの変更操作（@Observable の変更通知と記録フックの窓口）
    func update(_ mutate: (inout GameEngine) -> Void) {
        let before = engine.phase
        mutate(&engine)
        let after = engine.phase
        guard before != after else { return }
        if case .turnResult(let outcome) = after {
            onTurnFinished?(engine, outcome)
        }
        if after == .finalResult {
            onGameFinished?(engine)
        }
    }

    var progressLine: String {
        "ラウンド \(engine.roundNumber)/\(engine.config.rounds) ・ \(engine.turnNumber)/\(engine.turnsPerRound)人目 ・ 回答者: \(engine.answerer.name)"
    }
}
