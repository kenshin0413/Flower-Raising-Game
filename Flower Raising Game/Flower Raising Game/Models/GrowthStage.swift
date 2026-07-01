/// 花の成長段階です。
/// growthの値から現在の段階を計算します。
enum GrowthStage: String, Codable {
    case seed
    case germination
    case sprout
    case youngLeaves
    case trueLeaves
    case foliage
    case growing
    case bud
    case blooming
    case bloom

    var displayName: String {
        switch self {
        case .seed:
            return "種"
        case .germination:
            return "発芽"
        case .sprout:
            return "芽"
        case .youngLeaves:
            return "若芽"
        case .trueLeaves:
            return "本葉"
        case .foliage:
            return "葉っぱ"
        case .growing:
            return "成葉"
        case .bud:
            return "つぼみ"
        case .blooming:
            return "咲き始め"
        case .bloom:
            return "開花"
        }
    }

    var emoji: String {
        switch self {
        case .seed:
            return "🌰"
        case .germination:
            return "🌱"
        case .sprout:
            return "🌱"
        case .youngLeaves:
            return "🌿"
        case .trueLeaves:
            return "🌿"
        case .foliage:
            return "🌿"
        case .growing:
            return "🌿"
        case .bud:
            return "🪴"
        case .blooming:
            return "🌸"
        case .bloom:
            return "🌸"
        }
    }

    static func stage(for growth: Double) -> GrowthStage {
        switch stageNumber(for: growth) {
        case 1:
            return .seed
        case 2:
            return .germination
        case 3:
            return .sprout
        case 4:
            return .youngLeaves
        case 5:
            return .trueLeaves
        case 6:
            return .foliage
        case 7:
            return .growing
        case 8:
            return .bud
        case 9:
            return .blooming
        default:
            return .bloom
        }
    }

    private static func stageNumber(for growth: Double) -> Int {
        let stageNumber = Int((growth / 100 * 9).rounded()) + 1
        return min(max(stageNumber, 1), 10)
    }
}
