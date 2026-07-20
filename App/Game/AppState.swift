import Foundation
import Observation
import KanjiCore

/// アプリ全体の状態（プレイヤー台帳・お題・記録・購入状態）。
/// v1のMVPでは UserDefaults に Codable JSON で永続化する（SwiftData移行は後続）。
@MainActor
@Observable
final class AppState {
    // プレイヤー台帳
    private(set) var roster: [Player]
    var selectedPlayerIDs: Set<Player.ID> = []

    // お題
    let builtinTopics: [Topic]
    let freeTopicIDs: Set<String>
    private(set) var customTopics: [Topic]

    // ゲーム設定（ドラフト）
    var rounds = 1
    var charsPerPlayer = 2
    var difficulty: Difficulty = .normal
    var useCustomTopics = false
    var answererMode: AnswererMode = .sequential
    var timerSeconds: Int?  // nil = 無制限

    // 記録・購入・設定
    private(set) var records: [GameRecord]
    var purchased: Bool { didSet { defaults.set(purchased, forKey: Keys.purchased) } }
    var soundOn: Bool { didSet { defaults.set(soundOn, forKey: Keys.sound) } }
    let store = StoreManager()
    let ads = AdsManager()

    // 進行中ゲーム
    var gameSession: GameSession?
    // 中断中ゲーム（v1はアプリ起動中のみ保持。完全終了で消える）
    private(set) var suspendedSession: GameSession?
    private var suspendedTurns: [TurnRecord] = []

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let roster = "roster.v1"
        static let customTopics = "customTopics.v1"
        static let records = "records.v1"
        static let purchased = "purchased.v1"
        static let sound = "sound.v1"
    }

    static let freeMaxRounds = 2

    init() {
        let loaded = Self.loadBuiltinTopics()
        builtinTopics = loaded.topics
        freeTopicIDs = loaded.freeIDs
        roster = Self.load([Player].self, key: Keys.roster) ?? []
        customTopics = Self.load([Topic].self, key: Keys.customTopics) ?? []
        records = Self.load([GameRecord].self, key: Keys.records) ?? []
        purchased = UserDefaults.standard.bool(forKey: Keys.purchased)
        soundOn = UserDefaults.standard.object(forKey: Keys.sound) as? Bool ?? true

        store.onEntitlementChange = { [weak self] owned in
            self?.purchased = owned
        }
        store.start()
        if !purchased {
            ads.start()
        }
    }

    // MARK: - プレイヤー台帳

    func addPlayer(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let player = Player(name: trimmed)
        roster.append(player)
        selectedPlayerIDs.insert(player.id)
        save(roster, key: Keys.roster)
    }

    func toggleSelection(_ id: Player.ID) {
        if selectedPlayerIDs.contains(id) {
            selectedPlayerIDs.remove(id)
        } else {
            selectedPlayerIDs.insert(id)
        }
    }

    var selectedPlayers: [Player] { roster.filter { selectedPlayerIDs.contains($0.id) } }

    // MARK: - 自作お題（買い切り限定）

    func addCustomTopic(text: String, furigana: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let kana = furigana.trimmingCharacters(in: .whitespaces)
        customTopics.append(Topic(id: "custom-\(UUID().uuidString)", text: trimmed,
                                  furigana: kana.isEmpty ? trimmed : kana, difficulty: .normal))
        save(customTopics, key: Keys.customTopics)
    }

    func removeCustomTopic(_ id: Topic.ID) {
        customTopics.removeAll { $0.id == id }
        save(customTopics, key: Keys.customTopics)
    }

    // MARK: - ゲーム開始・終了

    var maxRounds: Int { purchased ? 5 : Self.freeMaxRounds }

    /// 現在の購入状態で遊べる通常お題（無料版は各難易度10問）
    func availableTopics(for difficulty: Difficulty) -> [Topic] {
        builtinTopics.filter { $0.difficulty == difficulty }
            .filter { purchased || freeTopicIDs.contains($0.id) }
    }

    func lockedTopicCount(for difficulty: Difficulty) -> Int {
        builtinTopics.filter { $0.difficulty == difficulty }.count - availableTopics(for: difficulty).count
    }

    func startGame() throws {
        let topics = useCustomTopics ? customTopics : availableTopics(for: difficulty)
        let config = try GameConfig(
            players: selectedPlayers,
            rounds: rounds,
            charsPerPlayer: charsPerPlayer,
            answererMode: answererMode,
            timer: timerSeconds.map(TimeInterval.init)
        )
        let session = GameSession(config: config, topics: topics)
        session.onTurnFinished = { [weak self] engine, outcome in
            self?.pendingTurns.append(TurnRecord(engine: engine, outcome: outcome))
        }
        session.onGameFinished = { [weak self] engine in
            self?.recordGame(engine: engine)
        }
        pendingTurns = []
        gameSession = session
    }

    func endGame() {
        gameSession = nil
        pendingTurns = []
    }

    // MARK: - 中断・再開

    /// 進行を保持したままホームへ戻る
    func suspendGame() {
        suspendedSession = gameSession
        suspendedTurns = pendingTurns
        gameSession = nil
        pendingTurns = []
    }

    func resumeGame() {
        pendingTurns = suspendedTurns
        gameSession = suspendedSession
        suspendedSession = nil
        suspendedTurns = []
    }

    func discardSuspendedGame() {
        suspendedSession = nil
        suspendedTurns = []
    }

    /// 進行を破棄して終了（記録には残さない）
    func abandonGame() {
        gameSession = nil
        pendingTurns = []
    }

    private var pendingTurns: [TurnRecord] = []

    private func recordGame(engine: GameEngine) {
        let name: (Player.ID) -> String = { id in
            engine.config.players.first { $0.id == id }?.name ?? "?"
        }
        let record = GameRecord(
            date: Date(),
            playerNames: engine.config.players.map(\.name),
            rounds: engine.config.rounds,
            turns: pendingTurns,
            totals: Dictionary(uniqueKeysWithValues: engine.totalScores.map { (name($0.key), $0.value) })
        )
        records.insert(record, at: 0)
        save(records, key: Keys.records)
    }

    // MARK: - 永続化

    private func save(_ value: some Encodable, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func loadBuiltinTopics() -> (topics: [Topic], freeIDs: Set<String>) {
        struct Entry: Decodable {
            let id: String
            let text: String
            let furigana: String
            let difficulty: Difficulty
            let category: String
            let free: Bool
        }
        struct TopicFile: Decodable {
            let schemaVersion: Int
            let topics: [Entry]
        }
        guard let url = Bundle.main.url(forResource: "topics", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(TopicFile.self, from: data) else {
            return ([], [])
        }
        let topics = file.topics.map {
            Topic(id: $0.id, text: $0.text, furigana: $0.furigana, difficulty: $0.difficulty)
        }
        let freeIDs = Set(file.topics.filter(\.free).map(\.id))
        return (topics, freeIDs)
    }
}
