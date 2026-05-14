import CoreLocation
import Foundation

/// 実際の天気APIから取得した現在天気です。
struct CurrentWeather {
    let type: WeatherType
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let isDay: Bool
}

/// 天気を取得する役割です。
/// Open-MeteoはAPIキーなしで現在の天気コード・気温・湿度・風速・昼夜情報を取得できます。
protocol WeatherServicing {
    func currentWeather(for coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather
}

final class OpenMeteoWeatherService: WeatherServicing {
    func currentWeather(for coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coordinate.latitude)"),
            URLQueryItem(name: "longitude", value: "\(coordinate.longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw WeatherServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let weatherType = Self.weatherType(
            weatherCode: decoded.current.weatherCode,
            windSpeed: decoded.current.windSpeed
        )

        return CurrentWeather(
            type: weatherType,
            temperature: decoded.current.temperature,
            humidity: decoded.current.humidity,
            windSpeed: decoded.current.windSpeed,
            isDay: decoded.current.isDay == 1
        )
    }

    private static func weatherType(weatherCode: Int, windSpeed: Double) -> WeatherType {
        if windSpeed >= 35 {
            return .windy
        }

        switch weatherCode {
        case 0, 1:
            return .sunny
        case 2, 3, 45, 48:
            return .cloudy
        case 51...67, 80...82, 85...86:
            return .rainy
        case 95...99:
            return .stormy
        default:
            return .cloudy
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let current: OpenMeteoCurrent
}

private struct OpenMeteoCurrent: Decodable {
    let temperature: Double
    let humidity: Double
    let weatherCode: Int
    let windSpeed: Double
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case isDay = "is_day"
    }
}

enum WeatherServiceError: Error {
    case invalidURL
    case invalidResponse
}
