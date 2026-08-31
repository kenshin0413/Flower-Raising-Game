import Foundation
import WidgetKit

/// 花の状態を保存・読み込みする役割です。
/// 今はUserDefaultsですが、将来CloudKitやファイル保存に変える場合もViewModel側の変更を小さくできます。
protocol FlowerStorageServicing {
    func loadFlower() -> FlowerState?
    func saveFlower(_ flower: FlowerState)
}

final class FlowerStorageService: FlowerStorageServicing {
    static let appGroupIdentifier = "group.com.kenshin.Flower-Raising-Game"
    static let storageKey = "flower_state_v1"

    private let storageKey = FlowerStorageService.storageKey
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults
            ?? UserDefaults(suiteName: FlowerStorageService.appGroupIdentifier)
            ?? .standard

        migrateLegacyFlowerIfNeeded()
    }

    func loadFlower() -> FlowerState? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(FlowerState.self, from: data)
        } catch {
            // 保存形式が変わった場合などは、壊れたデータを無視して初期状態から始めます。
            return nil
        }
    }

    func saveFlower(_ flower: FlowerState) {
        do {
            let data = try JSONEncoder().encode(flower)
            userDefaults.set(data, forKey: storageKey)
            // Widget Extensionがreload直後に古い値を読まないよう、App Groupへの書き込みを確定します。
            userDefaults.synchronize()
            WidgetCenter.shared.reloadTimelines(ofKind: "FlowerCareWidgetV2")
        } catch {
            // MVPでは保存失敗時のUI表示は行わず、デバッグログだけに留めます。
            print("Failed to save flower state: \(error)")
        }
    }


    /// 既存ユーザーの花を、アプリ専用領域からウィジェットと共有できる領域へ一度だけ移します。
    private func migrateLegacyFlowerIfNeeded() {
        guard userDefaults.data(forKey: storageKey) == nil,
              let legacyData = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        userDefaults.set(legacyData, forKey: storageKey)
    }
}
