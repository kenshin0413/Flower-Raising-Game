import Foundation

struct AppUpdateInfo: Identifiable, Equatable {
    let id = UUID()
    let currentVersion: String
    let latestVersion: String
    let storeURL: URL
}

@MainActor
final class AppUpdateService: ObservableObject {
    @Published private(set) var availableUpdate: AppUpdateInfo?

    private struct LookupResponse: Decodable {
        let resultCount: Int
        let results: [LookupResult]
    }

    private struct LookupResult: Decodable {
        let version: String
        let trackViewUrl: String?
    }

    private let session: URLSession
    private let bundle: Bundle
    private let userDefaults: UserDefaults
    private let lastCheckedAtKey = "appUpdate.lastCheckedAt"
    private let checkInterval: TimeInterval = 60 * 60 * 12

    private var isChecking = false
    private var dismissedUpdateVersion: String?

    init(
        session: URLSession = .shared,
        bundle: Bundle = .main,
        userDefaults: UserDefaults = .standard
    ) {
        self.session = session
        self.bundle = bundle
        self.userDefaults = userDefaults
    }

    func checkForUpdateIfNeeded(force: Bool = false) async {
        guard !isChecking else {
            return
        }

        if !force,
           let lastCheckedAt = userDefaults.object(forKey: lastCheckedAtKey) as? Date,
           Date().timeIntervalSince(lastCheckedAt) < checkInterval {
            return
        }

        await checkForUpdate()
    }

    func dismissCurrentUpdate() {
        dismissedUpdateVersion = availableUpdate?.latestVersion
        availableUpdate = nil
    }

    private func checkForUpdate() async {
        guard let bundleID = bundle.bundleIdentifier,
              let currentVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
              let lookupURL = lookupURL(bundleID: bundleID) else {
            return
        }

        isChecking = true
        defer {
            isChecking = false
        }

        do {
            let (data, _) = try await session.data(from: lookupURL)
            userDefaults.set(Date(), forKey: lastCheckedAtKey)

            let response = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard response.resultCount > 0,
                  let result = response.results.first,
                  isStoreVersion(result.version, newerThan: currentVersion),
                  dismissedUpdateVersion != result.version else {
                return
            }

            let storeURL = result.trackViewUrl.flatMap(URL.init(string:))
                ?? fallbackStoreURL(bundleID: bundleID)

            availableUpdate = AppUpdateInfo(
                currentVersion: currentVersion,
                latestVersion: result.version,
                storeURL: storeURL
            )
        } catch {
            // アップデート確認はユーザー操作を妨げない補助機能なので、失敗時は黙って次回に回します。
        }
    }

    private func lookupURL(bundleID: String) -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: "jp")
        ]
        return components?.url
    }

    private func fallbackStoreURL(bundleID: String) -> URL {
        URL(string: "https://apps.apple.com/jp/app/id?bundleId=\(bundleID)")!
    }

    private func isStoreVersion(_ storeVersion: String, newerThan currentVersion: String) -> Bool {
        compareVersions(storeVersion, currentVersion) == .orderedDescending
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = versionParts(lhs)
        let rhsParts = versionParts(rhs)
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0..<count {
            let lhsValue = index < lhsParts.count ? lhsParts[index] : 0
            let rhsValue = index < rhsParts.count ? rhsParts[index] : 0

            if lhsValue > rhsValue {
                return .orderedDescending
            }

            if lhsValue < rhsValue {
                return .orderedAscending
            }
        }

        return .orderedSame
    }

    private func versionParts(_ version: String) -> [Int] {
        version
            .split { character in
                character == "." || character == "-" || character == "_"
            }
            .map { Int($0) ?? 0 }
    }
}
