import AppTrackingTransparency
import Foundation

@MainActor
enum TrackingAuthorizationService {
    private static var didRequestThisLaunch = false

    static func requestIfNeeded() {
        guard !didRequestThisLaunch else {
            return
        }

        didRequestThisLaunch = true

        guard #available(iOS 14, *) else {
            return
        }

        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            return
        }

        ATTrackingManager.requestTrackingAuthorization { _ in }
    }
}
