import Foundation
import Observation
import GoogleMobileAds
import UserMessagingPlatform
import UIKit

/// 広告の窓口（無料版のみ）。UMPで同意を取り、非パーソナライズ広告で開始する。
/// 開発中はGoogle公式のテストユニットIDを使用。リリース時に差し替える。
@MainActor
@Observable
final class AdsManager: NSObject {
    // テスト用ユニットID（Google公式）
    static let bannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    private(set) var ready = false
    private var interstitial: InterstitialAd?
    private var interstitialCompletion: (() -> Void)?

    func start() {
        Task { await requestConsentAndStart() }
    }

    private func requestConsentAndStart() async {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            if ConsentInformation.shared.formStatus == .available {
                try await ConsentForm.loadAndPresentIfRequired(from: nil)
            }
        } catch {
            // 同意フローの失敗時は広告なしで続行（ゲームは遊べる）
        }
        guard ConsentInformation.shared.canRequestAds else { return }
        await MobileAds.shared.start()
        ready = true
        await loadInterstitial()
    }

    func loadInterstitial() async {
        guard ready else { return }
        let request = Request()
        // 非パーソナライズ広告で開始（ATT未実装のため）
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        interstitial = try? await InterstitialAd.load(with: Self.interstitialUnitID, request: request)
        interstitial?.fullScreenContentDelegate = self
    }

    /// ラウンド結果の後に表示。表示できない場合は即completionを呼ぶ
    func showInterstitial(completion: @escaping () -> Void) {
        guard let interstitial else {
            completion()
            return
        }
        interstitialCompletion = completion
        interstitial.present(from: nil)
    }
}

extension AdsManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        interstitialCompletion?()
        interstitialCompletion = nil
        Task { await loadInterstitial() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitial = nil
        interstitialCompletion?()
        interstitialCompletion = nil
    }
}
