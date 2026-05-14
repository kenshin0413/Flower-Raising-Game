import Foundation

/// 花の状態を保存・読み込みする役割です。
/// 今はUserDefaultsですが、将来CloudKitやファイル保存に変える場合もViewModel側の変更を小さくできます。
protocol FlowerStorageServicing {
    func loadFlower() -> FlowerState?
    func saveFlower(_ flower: FlowerState)
}

final class FlowerStorageService: FlowerStorageServicing {
    private let storageKey = "flower_state_v1"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
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
        } catch {
            // MVPでは保存失敗時のUI表示は行わず、デバッグログだけに留めます。
            print("Failed to save flower state: \(error)")
        }
    }
}
