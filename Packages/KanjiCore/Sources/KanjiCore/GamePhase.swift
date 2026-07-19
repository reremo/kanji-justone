import Foundation

public enum GamePhase: Equatable, Sendable {
    case answererReveal, topicGate, topicReveal
    case hintHandoff, hintInput, hintConfirm
    case answerHandoff, answerInput, judge, ranking
    case turnResult(TurnOutcome)
    case roundResult, finalResult
}
