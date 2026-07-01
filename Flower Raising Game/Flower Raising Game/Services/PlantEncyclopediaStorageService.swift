import Foundation

protocol PlantEncyclopediaStorageServicing {
    func loadRecords() -> [PlantBloomRecord]
    func saveRecords(_ records: [PlantBloomRecord])
}

final class PlantEncyclopediaStorageService: PlantEncyclopediaStorageServicing {
    private let storageKey = "plant_bloom_records_v1"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadRecords() -> [PlantBloomRecord] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([PlantBloomRecord].self, from: data)
        } catch {
            return []
        }
    }

    func saveRecords(_ records: [PlantBloomRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save plant bloom records: \(error)")
        }
    }
}
