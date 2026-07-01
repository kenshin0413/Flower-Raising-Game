import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdService: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published private(set) var isLoading = false

    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    private let adUnitID = "ca-app-pub-2277987033120510/6658532406"
    #endif
    private var rewardedAd: RewardedAd?
    private var rewardContinuation: CheckedContinuation<Bool, Never>?
    private var didEarnReward = false

    func showRewardedAd() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await RewardedAd.load(with: adUnitID, request: Request())
            rewardedAd = ad
            ad.fullScreenContentDelegate = self
            didEarnReward = false

            return await withCheckedContinuation { continuation in
                rewardContinuation = continuation
                ad.present(from: nil) {
                    self.didEarnReward = true
                }
            }
        } catch {
            return false
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardContinuation?.resume(returning: didEarnReward)
        rewardContinuation = nil
        rewardedAd = nil
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardContinuation?.resume(returning: false)
        rewardContinuation = nil
        rewardedAd = nil
    }
}
