/// 花の成長段階です。
/// growthの値から現在の段階を計算します。
enum GrowthStage: String, Codable {
    case seed
    case sprout
    case leaves
    case bud
    case bloom

    var displayName: String {
        switch self {
        case .seed:
            return "種"
        case .sprout:
            return "芽"
        case .leaves:
            return "葉っぱ"
        case .bud:
            return "つぼみ"
        case .bloom:
            return "開花"
        }
    }

    var emoji: String {
        switch self {
        case .seed:
            return "🌰"
        case .sprout:
            return "🌱"
        case .leaves:
            return "🌿"
        case .bud:
            return "🪴"
        case .bloom:
            return "🌸"
        }
    }

    static func stage(for growth: Double) -> GrowthStage {
        switch growth {
        case 0..<20:
            return .seed
        case 20..<45:
            return .sprout
        case 45..<70:
            return .leaves
        case 70..<95:
            return .bud
        default:
            return .bloom
        }
    }
}
