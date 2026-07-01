import Foundation

enum BloomCareRank: String, Codable, CaseIterable {
    case s = "S"
    case a = "A"
    case b = "B"
    case c = "C"
}

struct PlantBloomRecord: Identifiable, Codable, Equatable {
    let id: String
    let plantID: String
    let plantName: String
    let bloomImageName: String
    let bloomedAt: Date
    let daysToBloom: Int
    let careRank: BloomCareRank
}
