import AudioToolbox
import Foundation

/// 効果音の共通窓口。設定（S20 サウンド）でOFFにできる。
/// MVPはシステムサウンドの代用。専用音源への差し替えは #9 の残タスク。
enum SoundPlayer {
    enum Effect {
        case tap, correct, wrong, wipeout, fanfare

        var systemSoundID: SystemSoundID {
            switch self {
            case .tap: 1104      // Tock
            case .correct: 1025  // 完了系
            case .wrong: 1053    // 低いブザー系
            case .wipeout: 1073  // エラー系
            case .fanfare: 1335  // 祝祭系
            }
        }
    }

    static func play(_ effect: Effect) {
        guard UserDefaults.standard.object(forKey: "sound.v1") as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
}
