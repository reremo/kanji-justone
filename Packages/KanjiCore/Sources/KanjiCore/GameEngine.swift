import Foundation

/// 漢字の力の1ゲームを駆動する状態機械。純粋な値型で、I/O を持たない。
/// 不正なイベント（現在フェーズで許可されないイベント）は無視される（no-op）。
public struct GameEngine {

    // MARK: - 公開（読み取り）

    public private(set) var phase: GamePhase
    public let config: GameConfig
    public private(set) var roundNumber: Int          // 1始まり
    public private(set) var turnNumber: Int           // ラウンド内1始まり

    /// fixed: P-1 / それ以外: P
    public var turnsPerRound: Int {
        if case .fixed = config.answererMode { return config.players.count - 1 }
        return config.players.count
    }

    public private(set) var answerer: Player
    public private(set) var topic: Topic?
    public private(set) var fates: [CharFate]         // 提出済み全文字の状態

    public var survivors: [CharFate] { fates.filter { $0.state == .survived } }
    public var deletedCount: Int { fates.filter { $0.state != .survived }.count }

    public private(set) var totalScores: [Player.ID: Int]
    public private(set) var lastTurnScores: [Player.ID: Int]

    /// 現ターンの出題者（回答者以外、順番どおり）
    public var hintGivers: [Player] { config.players.filter { $0.id != answerer.id } }

    /// hintHandoff/hintInput 中のみ非nil
    public var currentHintGiver: Player? {
        switch phase {
        case .hintHandoff, .hintInput:
            let givers = hintGivers
            return hintGiverIndex < givers.count ? givers[hintGiverIndex] : nil
        default:
            return nil
        }
    }

    public private(set) var answerText: String?

    /// グループ確認用: 生存文字を人物単位でグルーピングし、seedで決定的にシャッフルした配列
    public var confirmGroups: [[CharFate]] {
        var order: [Player.ID] = []
        var groups: [Player.ID: [CharFate]] = [:]
        for f in survivors {
            if groups[f.ownerID] == nil {
                order.append(f.ownerID)
                groups[f.ownerID] = []
            }
            groups[f.ownerID]?.append(f)
        }
        let s = combinedSeed(seed, UInt64(roundNumber), UInt64(turnNumber) &+ 0x1111)
        // グループ内の文字順も決定的にシャッフルし、提出順から誰が何を出したか読めないようにする
        let arr = order.enumerated().map { i, owner in
            groups[owner]!.deterministicShuffled(seed: combinedSeed(s, UInt64(i), 0x3333))
        }
        return arr.deterministicShuffled(seed: s)
    }

    /// ヒント確認用の表示グループ（人物単位・匿名）。
    /// tiles は生存＋手動削除（没）の札で、状態変化しても順序は不変。duplicateCount は自動重複削除の枚数。
    public struct ConfirmGroup: Identifiable, Sendable {
        public let id: Player.ID       // オーナーID（匿名だが安定した識別子）
        public let tiles: [CharFate]   // 表示する札（survived / manualDeleted）
        public let duplicateCount: Int // 自動重複削除された枚数（重複スタンプで表示）
    }

    /// 人物単位でグルーピングし決定的シャッフルしたヒント確認用グループ。
    /// - tiles: survived + manualDeleted（没を押しても復活できるよう手動削除も残す）
    /// - duplicateCount: autoDeleted の枚数（重複スタンプ）
    public var confirmDisplayGroups: [ConfirmGroup] {
        var order: [Player.ID] = []
        var tiles: [Player.ID: [CharFate]] = [:]
        var dups: [Player.ID: Int] = [:]
        for f in fates {
            if !order.contains(f.ownerID) { order.append(f.ownerID) }
            switch f.state {
            case .survived, .manualDeleted:
                tiles[f.ownerID, default: []].append(f)
            case .autoDeleted:
                dups[f.ownerID, default: 0] += 1
            }
        }
        let s = combinedSeed(seed, UInt64(roundNumber), UInt64(turnNumber) &+ 0x1111)
        let groups = order.enumerated().map { i, owner -> ConfirmGroup in
            let t = (tiles[owner] ?? []).deterministicShuffled(seed: combinedSeed(s, UInt64(i), 0x3333))
            return ConfirmGroup(id: owner, tiles: t, duplicateCount: dups[owner] ?? 0)
        }
        return groups.deterministicShuffled(seed: s)
    }

    /// 回答用: 生存文字をフラットに決定的シャッフルした配列
    public var flatSurvivors: [CharFate] {
        let s = combinedSeed(seed, UInt64(roundNumber), UInt64(turnNumber) &+ 0x2222)
        return survivors.deterministicShuffled(seed: s)
    }

    /// 回答用: 削除された文字（自動=重複／手動=没）をフラットに決定的シャッフルした配列。
    /// 文字自体はUI側で伏せる（重複/没の別だけ見せる）。
    public var flatDeleted: [CharFate] {
        let s = combinedSeed(seed, UInt64(roundNumber), UInt64(turnNumber) &+ 0x4444)
        return fates.filter { $0.state != .survived }.deterministicShuffled(seed: s)
    }

    // MARK: - 内部状態

    private let seed: UInt64
    private let topics: [Topic]
    private var topicRNG: SplitMix64
    private var usedTopicIDs: Set<String>
    private var hintGiverIndex: Int

    // MARK: - 初期化

    public init(config: GameConfig, topics: [Topic], seed: UInt64) {
        self.config = config
        self.topics = topics
        self.seed = seed
        self.topicRNG = SplitMix64(seed: seed)
        self.usedTopicIDs = []
        self.roundNumber = 1
        self.turnNumber = 1
        self.hintGiverIndex = 0
        self.fates = []
        self.answerText = nil
        self.topic = nil
        self.phase = .answererReveal

        var totals: [Player.ID: Int] = [:]
        for p in config.players { totals[p.id] = 0 }
        self.totalScores = totals
        self.lastTurnScores = [:]

        // 1ターン目のセットアップ
        self.answerer = config.players[0] // answererOrder が self を要するための仮値
        self.answerer = answererOrder(forRound: 1)[0]
        drawTopic()
    }

    // MARK: - イベント

    public mutating func proceedFromAnswererReveal() {
        guard phase == .answererReveal else { return }
        phase = .topicGate
    }

    public mutating func confirmAnswererNotLooking() {
        guard phase == .topicGate else { return }
        phase = .topicReveal
    }

    public mutating func skipTopic() {
        guard phase == .topicReveal else { return }
        drawTopic()
    }

    public mutating func finishTopicViewing() {
        guard phase == .topicReveal else { return }
        hintGiverIndex = 0
        phase = .hintHandoff
    }

    public mutating func confirmHintPerson() {
        guard phase == .hintHandoff else { return }
        phase = .hintInput
    }

    @discardableResult
    public mutating func submitHint(chars: [Character]) -> HintValidationError? {
        guard phase == .hintInput else { return nil }
        let givers = hintGivers
        guard hintGiverIndex < givers.count else { return nil }
        if let error = HintRules.validate(chars: chars, expectedCount: config.charsPerPlayer) {
            return error
        }
        let giver = givers[hintGiverIndex]
        for c in chars {
            fates.append(CharFate(char: c, ownerID: giver.id, state: .survived))
        }
        hintGiverIndex += 1
        if hintGiverIndex < givers.count {
            phase = .hintHandoff
        } else {
            applyAutoDedup()
            if survivors.isEmpty {
                resolve(outcome: .wipeout)
            } else {
                phase = .hintConfirm
            }
        }
        return nil
    }

    public mutating func manuallyDelete(fateID: UUID) {
        guard phase == .hintConfirm else { return }
        guard let idx = fates.firstIndex(where: { $0.id == fateID && $0.state == .survived }) else { return }
        fates[idx].state = .manualDeleted
        if survivors.isEmpty {
            resolve(outcome: .wipeout)
        }
    }

    /// 没スタンプのトグル: survived ↔ manualDeleted を切り替える（autoDeleted は対象外）。
    /// 全滅判定は行わず、確認完了時（finishHintConfirm）にまとめて評価する。
    public mutating func toggleManualDelete(fateID: UUID) {
        guard phase == .hintConfirm else { return }
        guard let idx = fates.firstIndex(where: { $0.id == fateID }) else { return }
        switch fates[idx].state {
        case .survived:      fates[idx].state = .manualDeleted
        case .manualDeleted: fates[idx].state = .survived
        case .autoDeleted:   break
        }
    }

    public mutating func finishHintConfirm() {
        guard phase == .hintConfirm else { return }
        if survivors.isEmpty {
            resolve(outcome: .wipeout)
        } else {
            phase = .answerHandoff
        }
    }

    public mutating func answererReceived() {
        guard phase == .answerHandoff else { return }
        phase = .answerInput
    }

    public mutating func submitAnswer(_ text: String) {
        guard phase == .answerInput else { return }
        answerText = text
        phase = .judge
    }

    public mutating func judgeCorrect() {
        guard phase == .judge else { return }
        phase = .ranking
    }

    public mutating func judgeWrong() {
        guard phase == .judge else { return }
        phase = .answerInput
    }

    public mutating func judgeGiveUp() {
        guard phase == .judge else { return }
        resolve(outcome: .giveUp)
    }

    public mutating func submitRanking(orderedFateIDs: [UUID]) {
        guard phase == .ranking else { return }
        let survivorIDs = Set(survivors.map { $0.id })
        guard orderedFateIDs.count == survivorIDs.count,
              Set(orderedFateIDs) == survivorIDs else { return }
        for (i, fid) in orderedFateIDs.enumerated() {
            if let idx = fates.firstIndex(where: { $0.id == fid }) {
                fates[idx].rank = i + 1
            }
        }
        resolve(outcome: .correct)
    }

    public mutating func proceedFromTurnResult() {
        guard case .turnResult = phase else { return }
        if turnNumber < turnsPerRound {
            turnNumber += 1
            startTurn()
        } else if roundNumber < config.rounds {
            phase = .roundResult
        } else {
            phase = .finalResult
        }
    }

    public mutating func proceedFromRoundResult() {
        guard phase == .roundResult else { return }
        roundNumber += 1
        turnNumber = 1
        startTurn()
    }

    // MARK: - 内部ヘルパ

    private mutating func startTurn() {
        answerer = answererOrder(forRound: roundNumber)[turnNumber - 1]
        fates = []
        hintGiverIndex = 0
        answerText = nil
        lastTurnScores = [:]
        drawTopic()
        phase = .answererReveal
    }

    private func answererOrder(forRound round: Int) -> [Player] {
        switch config.answererMode {
        case .sequential:
            return config.players
        case .roundRobin:
            let s = combinedSeed(seed, UInt64(round), 0xA5A5)
            return config.players.deterministicShuffled(seed: s)
        case .fixed(let id):
            let p = config.players.first { $0.id == id }!
            return Array(repeating: p, count: max(1, config.players.count - 1))
        }
    }

    private mutating func drawTopic() {
        var candidates = topics.filter { !usedTopicIDs.contains($0.id) }
        if candidates.isEmpty {
            // プール枯渇時はリセットするが、直前のお題だけは除外して連続出題を防ぐ
            usedTopicIDs.removeAll()
            if let current = topic?.id { usedTopicIDs.insert(current) }
            candidates = topics.filter { !usedTopicIDs.contains($0.id) }
            if candidates.isEmpty { candidates = topics }
        }
        guard !candidates.isEmpty else {
            topic = nil
            return
        }
        let idx = Int(topicRNG.next() % UInt64(candidates.count))
        let chosen = candidates[idx]
        usedTopicIDs.insert(chosen.id)
        topic = chosen
    }

    private mutating func applyAutoDedup() {
        var counts: [Character: Int] = [:]
        for f in fates { counts[f.char, default: 0] += 1 }
        for i in fates.indices where (counts[fates[i].char] ?? 0) > 1 {
            fates[i].state = .autoDeleted
        }
    }

    private mutating func resolve(outcome: TurnOutcome) {
        switch outcome {
        case .giveUp, .wipeout:
            applyZeroScores()
        case .correct:
            applyCorrectScores()
        }
        phase = .turnResult(outcome)
    }

    private mutating func applyZeroScores() {
        var last: [Player.ID: Int] = [:]
        for p in config.players { last[p.id] = 0 }
        lastTurnScores = last
        // totalScores は加算0で変化なし
    }

    private mutating func applyCorrectScores() {
        let P = config.players.count
        var scores: [Player.ID: Int] = [:]

        // 回答者: +P + 削除合計数（自動+手動）
        scores[answerer.id] = P + deletedCount

        // 出題者: 各自の生存漢字の最高順位（数値が小さいほど良い）の昇順に並べ、1位 +P, 2位 +P-1, …
        // 生存0の出題者は0点（順位付け対象外）
        var bests: [(id: Player.ID, best: Int)] = []
        for giver in hintGivers {
            let mine = fates.filter { $0.ownerID == giver.id && $0.state == .survived }
            if let best = mine.compactMap({ $0.rank }).min() {
                bests.append((giver.id, best))
            }
        }
        bests.sort { $0.best < $1.best }
        for (i, entry) in bests.enumerated() {
            scores[entry.id] = P - i
        }

        var last: [Player.ID: Int] = [:]
        for p in config.players { last[p.id] = scores[p.id] ?? 0 }
        lastTurnScores = last
        for p in config.players { totalScores[p.id, default: 0] += last[p.id]! }
    }
}
