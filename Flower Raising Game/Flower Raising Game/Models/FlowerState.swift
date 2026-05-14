import Foundation

/// 1つの花の状態を表す保存用データです。
/// CodableにしておくとUserDefaultsへJSONとして保存しやすくなります。
struct FlowerState: Codable {
    var name: String
    var water: Double
    var sunlight: Double
    var nutrition: Double
    var mood: Double
    var growth: Double
    var selectedWeather: WeatherType
    var lastOpenedAt: Date
    /// 水やりを最後にした日時です。nilの場合は、まだ一度も水やりしていない状態です。
    var lastWateredAt: Date?
    /// 日光を最後にあげた日時です。将来、実際の天気連動に置き換える時もここを基準にできます。
    var lastSunlightAt: Date?
    /// 肥料を最後にあげた日時です。
    var lastFedAt: Date?
    /// 水分・日光・栄養・気分の悪い状態が続いた時間です。24時間を超えるとしおれ始めます。
    var stressHours: Double?
    /// 枯れに近づいている時間です。しおれたまま悪い状態が続くと増え、一定値で枯れます。
    var fatalStressHours: Double?
    /// 最後に水やり・日光・肥料のどれかを行った日です。
    var lastCareDate: Date?
    /// 連続でお世話できている日数です。
    var careStreak: Int?
    /// 現実の天気を最後に育成状態へ反映した日時です。天気効果の重複適用を防ぎます。
    var lastWeatherAppliedAt: Date?
    /// 最後に取得した湿度です。アプリを閉じていた間の水分変化補正に使います。
    var lastHumidity: Double?
    /// 最後に取得した風速です。Open-Meteoの値に合わせてkm/hで保存します。
    var lastWindSpeed: Double?

    var growthStage: GrowthStage {
        GrowthStage.stage(for: growth)
    }

    static let initial = FlowerState(
        name: "はるの花",
        water: 55,
        sunlight: 55,
        nutrition: 55,
        mood: 70,
        growth: 0,
        selectedWeather: .sunny,
        lastOpenedAt: Date(),
        lastWateredAt: nil,
        lastSunlightAt: nil,
        lastFedAt: nil,
        stressHours: nil,
        fatalStressHours: nil,
        lastCareDate: nil,
        careStreak: nil,
        lastWeatherAppliedAt: nil,
        lastHumidity: nil,
        lastWindSpeed: nil
    )
}
