import AudioToolbox
import AVFoundation
import Foundation

/// 効果音の共通窓口。設定（S20 サウンド）でOFFにできる。
/// バンドル音源があればそれを、無ければシステムサウンドで代用する（差し替えは #9）。
enum SoundPlayer {
    enum Effect {
        case tap, correct, wrong, wipeout, fanfare

        /// バンドル同梱の音源ファイル名（拡張子なし）。無い場合はシステム音にフォールバック。
        var resourceName: String? {
            switch self {
            case .wipeout: "wipeout"   // 全滅：下降する残念トロンボーン
            default: nil
            }
        }

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

    private static var players: [String: AVAudioPlayer] = [:]

    static func play(_ effect: Effect) {
        guard UserDefaults.standard.object(forKey: "sound.v1") as? Bool ?? true else { return }
        if let name = effect.resourceName, playFile(name) { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }

    /// バンドル音源を再生。見つからなければ false を返しシステム音にフォールバックさせる。
    private static func playFile(_ name: String) -> Bool {
        let player: AVAudioPlayer
        if let cached = players[name] {
            player = cached
        } else {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
                  let p = try? AVAudioPlayer(contentsOf: url) else { return false }
            p.prepareToPlay()
            players[name] = p
            player = p
        }
        player.currentTime = 0
        player.play()
        return true
    }
}
