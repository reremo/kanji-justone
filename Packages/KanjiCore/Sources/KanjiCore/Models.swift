import Foundation

public struct Player: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public enum Difficulty: String, Codable, Sendable {
    case easy, normal, hard
}

public struct Topic: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let text: String
    public let furigana: String
    public let difficulty: Difficulty
    public init(id: String, text: String, furigana: String, difficulty: Difficulty) {
        self.id = id
        self.text = text
        self.furigana = furigana
        self.difficulty = difficulty
    }
}

public enum AnswererMode: Hashable, Codable, Sendable {
    case sequential
    case roundRobin
    case fixed(Player.ID)
}

public struct GameConfig: Sendable {
    public let players: [Player]        // 3〜8人
    public let rounds: Int              // 1以上
    public let charsPerPlayer: Int      // 1以上（既定2）
    public let answererMode: AnswererMode
    public let timer: TimeInterval?     // v1未使用・予約

    public init(
        players: [Player],
        rounds: Int,
        charsPerPlayer: Int = 2,
        answererMode: AnswererMode = .sequential,
        timer: TimeInterval? = nil
    ) throws {
        guard (3...8).contains(players.count) else { throw GameConfigError.invalidPlayerCount }
        guard rounds >= 1 else { throw GameConfigError.invalidRounds }
        guard charsPerPlayer >= 1 else { throw GameConfigError.invalidCharsPerPlayer }
        if case .fixed(let id) = answererMode {
            guard players.contains(where: { $0.id == id }) else {
                throw GameConfigError.fixedAnswererNotInPlayers
            }
        }
        self.players = players
        self.rounds = rounds
        self.charsPerPlayer = charsPerPlayer
        self.answererMode = answererMode
        self.timer = timer
    }
}

public enum GameConfigError: Error, Equatable {
    case invalidPlayerCount
    case invalidRounds
    case invalidCharsPerPlayer
    case fixedAnswererNotInPlayers
}

public enum CharState: Equatable, Sendable {
    case survived, autoDeleted, manualDeleted
}

public struct CharFate: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let char: Character
    public let ownerID: Player.ID
    public var state: CharState
    public var rank: Int?               // 採点後、生存文字のみ 1..N

    public init(id: UUID = UUID(), char: Character, ownerID: Player.ID, state: CharState = .survived, rank: Int? = nil) {
        self.id = id
        self.char = char
        self.ownerID = ownerID
        self.state = state
        self.rank = rank
    }
}

public enum TurnOutcome: Equatable, Sendable {
    case correct, giveUp, wipeout
}
