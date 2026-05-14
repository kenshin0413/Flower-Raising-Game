import SwiftUI

/// MVPで使う仮の天気です。
/// 将来CoreLocationやOpenWeatherMap APIを入れるときは、
/// APIの天気コードをこの enum に変換するとViewModelのロジックを再利用できます。
enum WeatherType: String, CaseIterable, Codable, Identifiable {
    case sunny
    case cloudy
    case rainy
    case stormy
    case windy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunny:
            return "晴れ"
        case .cloudy:
            return "曇り"
        case .rainy:
            return "雨"
        case .stormy:
            return "嵐"
        case .windy:
            return "強風"
        }
    }

    var emoji: String {
        switch self {
        case .sunny:
            return "☀️"
        case .cloudy:
            return "☁️"
        case .rainy:
            return "🌧️"
        case .stormy:
            return "⛈️"
        case .windy:
            return "💨"
        }
    }

    var tintColor: Color {
        switch self {
        case .sunny:
            return .yellow
        case .cloudy:
            return .gray
        case .rainy:
            return .blue
        case .stormy:
            return .purple
        case .windy:
            return .mint
        }
    }
}
