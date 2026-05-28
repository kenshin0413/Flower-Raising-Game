import Foundation
import SwiftUI

/// 花の状態管理と育成ロジックをまとめるViewModelです。
/// ViewはこのViewModelの値を表示し、ボタン操作をViewModelへ伝えるだけにします。
@MainActor
final class FlowerGardenViewModel: ObservableObject {
    private enum CareAction {
        case water
        case sunlight
        case fertilizer
    }

    @Published private(set) var flower: FlowerState
    @Published var selectedWeather: WeatherType
    @Published private(set) var lastTimeMessage: String = "今日も少しずつ育てましょう"
    @Published private(set) var currentTemperature: Double?
    @Published private(set) var currentHumidity: Double?
    @Published private(set) var currentWindSpeed: Double?
    @Published private(set) var currentPrecipitation: Double?
    @Published private(set) var isCurrentWeatherDaytime: Bool = true

    private let storageService: FlowerStorageServicing
    private let weatherService: WeatherServicing
    private let locationService: LocationService
    private var isRefreshingRealWeather = false
    private var midnightRefreshTask: Task<Void, Never>?

    init(
        storageService: FlowerStorageServicing = FlowerStorageService(),
        weatherService: WeatherServicing = OpenMeteoWeatherService(),
        locationService: LocationService = LocationService()
    ) {
        self.storageService = storageService
        self.weatherService = weatherService
        self.locationService = locationService

        let savedFlower = storageService.loadFlower() ?? FlowerState.initial
        self.flower = savedFlower
        self.selectedWeather = savedFlower.selectedWeather
        self.currentHumidity = savedFlower.lastHumidity
        self.currentWindSpeed = savedFlower.lastWindSpeed
        self.currentPrecipitation = savedFlower.lastPrecipitation

        applyOfflineProgressIfNeeded()

        Task {
            await refreshRealWeather()
        }

        scheduleMidnightRefresh()
    }

    deinit {
        midnightRefreshTask?.cancel()
    }

    var stageName: String {
        if isDead {
            return "枯れ状態"
        }

        if isWilted {
            return "しおれ気味"
        }

        return flower.growthStage.displayName
    }

    var flowerEmoji: String {
        flower.growthStage.emoji
    }

    var plantImageName: String? {
        let stageNumber = plantStageNumber(for: flower.growth)

        if isDead, stageNumber > 1 {
            let deadStageNumber = stageNumber == 4 ? 3 : stageNumber
            return String(format: "dead_stage_%02d", deadStageNumber)
        }

        if isWilted, stageNumber > 1 {
            return String(format: "wilted_stage_%02d", stageNumber)
        }

        if stageNumber == 1 {
            return "ChatGPT Image 2026年5月15日 12_33_35"
        }

        return String(format: "growth_stage_%02d", stageNumber)
    }

    var growthPercentText: String {
        let growth = clamped(flower.growth)
        let displayGrowth = growth > 0 && growth < 0.1 ? 0.1 : floor(growth * 10) / 10

        return String(format: "%.1f%%", displayGrowth)
    }

    var growthProgressPercent: Double {
        Double(displayGrowthPercent)
    }

    var stressPercent: Double {
        if isDead {
            return 100
        }

        let wiltProgress = min(currentStressHours / 24, 1) * 55
        let fatalProgress = min(currentFatalStressHours / 48, 1) * 45
        let currentConditionPressure = min(conditionStressScore / 6, 1) * 12

        return clamped(max(wiltProgress + fatalProgress, currentConditionPressure))
    }

    var deathRiskPercent: Double {
        if isDead {
            return 100
        }

        let conditionRisk = min(conditionStressScore / 6, 1) * 25
        let wiltRisk = min(currentStressHours / 24, 1) * 30
        let fatalRisk = min(currentFatalStressHours / 48, 1) * 70
        let rawRisk = conditionRisk + fatalRisk + (currentStressHours >= 18 ? wiltRisk : wiltRisk * 0.35)

        return clamped(rawRisk)
    }

    var temperatureText: String {
        if let currentTemperature {
            return "\(Int(currentTemperature.rounded()))°C"
        }

        switch flower.selectedWeather {
        case .sunny:
            return "23°C"
        case .cloudy:
            return "20°C"
        case .rainy:
            return "18°C"
        case .stormy:
            return "16°C"
        case .windy:
            return "19°C"
        }
    }

    var weatherDisplayName: String {
        isCurrentWeatherDaytime ? flower.selectedWeather.displayName : "夜・\(flower.selectedWeather.displayName)"
    }

    var weatherDisplayEmoji: String {
        isCurrentWeatherDaytime ? flower.selectedWeather.emoji : "🌙"
    }

    var humidityText: String {
        guard let currentHumidity else {
            return "--%"
        }

        return "\(Int(currentHumidity.rounded()))%"
    }

    var windSpeedText: String {
        guard let currentWindSpeed else {
            return "--m/s"
        }

        return String(format: "%.1fm/s", currentWindSpeed / 3.6)
    }

    var canWaterToday: Bool {
        !isDead && !hasUsedToday(flower.lastWateredAt)
    }

    var canGiveSunlightToday: Bool {
        !isDead && !hasUsedToday(flower.lastSunlightAt)
    }

    var canFeedToday: Bool {
        !isDead && !hasUsedToday(flower.lastFedAt)
    }

    var isFullyBloomed: Bool {
        flower.growth >= 100
    }

    var careStreakText: String {
        "\(max(currentCareStreak, 1))日継続"
    }

    var isWilted: Bool {
        !isDead && currentStressHours >= 24
    }

    var isDead: Bool {
        currentFatalStressHours >= 48 || currentStressHours >= 96
    }

    var careAdviceText: String {
        if isDead {
            return "枯れてしまいました。植え替えて新しく育てましょう"
        }

        if isFullyBloomed {
            return "きれいに開花しました。植え替えると新しい花を育てられます"
        }

        if currentFatalStressHours >= 24 {
            return "危険です。水分45-90%・日光55%以上・栄養45-90%へ戻そう"
        }

        if isWilted {
            return "しおれ中。まず不足ゲージを直して、1日安定させよう"
        }

        if flower.water >= 96 {
            return "水分過多です。水やりは止めて、日光55%以上を保とう"
        }

        if flower.nutrition >= 96 {
            return "栄養過多です。肥料は止めて、水分45-90%を保とう"
        }

        if flower.water < 20 {
            return canWaterToday ? "水やりで水分45%以上へ。理想は55-88%" : "水分不足です。明日0時に水やりして55-88%へ"
        }

        if flower.sunlight < 42 {
            return canGiveSunlightToday ? "ライトで日光42%以上へ。55%以上で育ちます" : "日光不足です。明日0時にライトで55%以上へ"
        }

        if flower.sunlight < 55 {
            return canGiveSunlightToday ? "日光55%以上が目標。ライトを使うと育ちやすいです" : "日光55%以上が目標。今日は水分と栄養を維持しよう"
        }

        if flower.nutrition < 25 {
            return canFeedToday ? "肥料で栄養45%以上へ。理想は55-90%" : "栄養不足です。明日0時に肥料で55-90%へ"
        }

        if deathRiskPercent >= 45 {
            return "枯れリスク高め。水分55-88%・日光55%以上・栄養55-90%へ"
        }

        if stressPercent >= 28 {
            return "ストレス高め。過不足を直して、今日は追加しすぎないようにしよう"
        }

        if flower.selectedWeather == .stormy {
            return "嵐の日は水分90%超えに注意。日光55%以上を優先しよう"
        }

        if flower.selectedWeather == .windy || (flower.lastWindSpeed ?? 0) >= 24 {
            return canWaterToday ? "風で乾きやすいです。水分55-88%を目標に水やりを判断" : "風で乾きやすいです。水分45%以上を維持しよう"
        }

        if let humidity = flower.lastHumidity {
            if humidity < 35 {
                return canWaterToday ? "乾燥中。水分55-88%を目標に水やりしよう" : "乾燥中。水分45%以上を切らないように注意"
            }

            if humidity >= 90 {
                return "湿度高め。水分90%超えなら水やりは控えよう"
            }
        }

        if !isCurrentWeatherDaytime {
            return canGiveSunlightToday ? "夜は自然日光なし。ライトで55%以上を狙おう" : "夜は水分55-88%・栄養55-90%を維持しよう"
        }

        return "順調です。水分55-88%・日光55%以上・栄養55-90%を維持"
    }

    var careAdviceSystemImage: String {
        if isDead {
            return "xmark.circle.fill"
        }

        if isFullyBloomed {
            return "sparkles"
        }

        if currentFatalStressHours >= 24 || deathRiskPercent >= 45 {
            return "flame.fill"
        }

        if isWilted || stressPercent >= 28 {
            return "exclamationmark.triangle.fill"
        }

        if flower.water >= 96 || flower.water < 20 {
            return "drop.fill"
        }

        if flower.sunlight < 55 || !isCurrentWeatherDaytime {
            return "sun.max.fill"
        }

        if flower.nutrition >= 96 || flower.nutrition < 25 {
            return "leaf.fill"
        }

        if flower.selectedWeather == .windy || (flower.lastWindSpeed ?? 0) >= 24 {
            return "wind"
        }

        return "checkmark.seal.fill"
    }

    var careAdviceColor: Color {
        if isDead || currentFatalStressHours >= 24 || deathRiskPercent >= 45 {
            return .red
        }

        if isFullyBloomed {
            return .green
        }

        if isWilted || stressPercent >= 28 || flower.water >= 96 || flower.nutrition >= 96 {
            return .orange
        }

        if flower.sunlight < 55 || flower.water < 20 || flower.nutrition < 25 {
            return .yellow
        }

        return .green
    }

    var waterStatusText: String? {
        switch flower.water {
        case 95...:
            return "危険"
        case 90..<95:
            return "多い"
        case ..<20:
            return "危険"
        case ..<45:
            return "少ない"
        default:
            return nil
        }
    }

    var waterStatusColor: Color {
        statusColor(for: waterStatusText)
    }

    var sunlightStatusText: String? {
        switch flower.sunlight {
        case 95...:
            return "多い"
        case ..<25:
            return "危険"
        case ..<55:
            return "少ない"
        default:
            return nil
        }
    }

    var sunlightStatusColor: Color {
        statusColor(for: sunlightStatusText)
    }

    var nutritionStatusText: String? {
        switch flower.nutrition {
        case 95...:
            return "危険"
        case 90..<95:
            return "多い"
        case ..<25:
            return "危険"
        case ..<45:
            return "少ない"
        default:
            return nil
        }
    }

    var nutritionStatusColor: Color {
        statusColor(for: nutritionStatusText)
    }

    var stressStatusText: String? {
        switch stressPercent {
        case 55...:
            return "危険"
        case 28..<55:
            return "高い"
        default:
            return nil
        }
    }

    var stressStatusColor: Color {
        statusColor(for: stressStatusText)
    }

    var deathRiskStatusText: String? {
        switch deathRiskPercent {
        case 65...:
            return "危険"
        case 35..<65:
            return "注意"
        default:
            return nil
        }
    }

    var deathRiskStatusColor: Color {
        statusColor(for: deathRiskStatusText)
    }

    func waterFlower() {
        guard canWaterToday, !isDead else {
            return
        }

        flower.water = clamped(flower.water + 9)
        flower.mood = clamped(flower.mood + 6)
        flower.lastWateredAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 8, fatalHours: 4)
        growIfConditionsAreGood(baseAmount: 0.58, action: .water)
        saveCurrentState()
    }

    func giveSunlight() {
        guard canGiveSunlightToday, !isDead else {
            return
        }

        flower.sunlight = clamped(flower.sunlight + 14)
        flower.water = clamped(flower.water - 5)
        flower.mood = clamped(flower.mood + 4)
        flower.lastSunlightAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 6, fatalHours: 3)
        growIfConditionsAreGood(baseAmount: 0.66, action: .sunlight)
        saveCurrentState()
    }

    func feedFlower() {
        guard canFeedToday, !isDead else {
            return
        }

        flower.nutrition = clamped(flower.nutrition + 7)
        flower.mood = clamped(flower.mood + 4)
        flower.lastFedAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 9, fatalHours: 4)
        growIfConditionsAreGood(baseAmount: 0.60, action: .fertilizer)
        saveCurrentState()
    }

    func applySelectedWeather() {
        guard !isDead else {
            return
        }

        applyWeatherEffect(selectedWeather)
        saveCurrentState()
    }

    func applyElapsedTimeIfNeeded() {
        applyOfflineProgressIfNeeded()
    }

    func refreshRealWeather() async {
        guard !isRefreshingRealWeather else {
            return
        }

        isRefreshingRealWeather = true
        defer {
            isRefreshingRealWeather = false
        }

        do {
            let coordinate = try await locationService.currentCoordinate()
            let currentWeather = try await weatherService.currentWeather(for: coordinate)

            currentTemperature = currentWeather.temperature
            currentHumidity = currentWeather.humidity
            currentWindSpeed = currentWeather.windSpeed
            currentPrecipitation = currentWeather.precipitation
            isCurrentWeatherDaytime = currentWeather.isDay
            selectedWeather = currentWeather.type
            flower.selectedWeather = currentWeather.type
            flower.lastHumidity = currentWeather.humidity
            flower.lastWindSpeed = currentWeather.windSpeed
            flower.lastPrecipitation = currentWeather.precipitation

            saveCurrentState()
        } catch {
            lastTimeMessage = "天気を取得できませんでした"
        }
    }

    private func applyWeatherEffect(_ weather: WeatherType) {
        guard !isDead else {
            return
        }

        flower.selectedWeather = weather

        switch weather {
        case .sunny:
            flower.sunlight = clamped(flower.sunlight + 22)
            flower.water = clamped(flower.water - 8)
            flower.mood = clamped(flower.mood + 6)
            growIfConditionsAreGood(baseAmount: 0.65)
        case .cloudy:
            flower.sunlight = clamped(flower.sunlight + 8)
            flower.water = clamped(flower.water - 2)
            flower.mood = clamped(flower.mood + 1)
            growIfConditionsAreGood(baseAmount: 0.2)
        case .rainy:
            flower.water = clamped(flower.water + 22)
            flower.sunlight = clamped(flower.sunlight - 5)
            flower.mood = clamped(flower.mood + 2)
            growIfConditionsAreGood(baseAmount: 0.3)
        case .stormy:
            flower.water = clamped(flower.water + 12)
            flower.sunlight = clamped(flower.sunlight - 10)
            flower.mood = clamped(flower.mood - 18)
            growIfConditionsAreGood(baseAmount: 0.05)
        case .windy:
            flower.water = clamped(flower.water - 6)
            flower.mood = clamped(flower.mood - 10)
            growIfConditionsAreGood(baseAmount: 0.08)
        }

        updateStressFromCurrentCondition(hours: 3)
    }

    func resetFlower() {
        flower = FlowerState.initial
        selectedWeather = flower.selectedWeather
        lastTimeMessage = "新しい花を育て始めました"
        saveCurrentState()
    }

    private func applyOfflineProgressIfNeeded(now: Date = Date()) {
        let elapsedSeconds = max(0, now.timeIntervalSince(flower.lastOpenedAt))
        let elapsedHours = elapsedSeconds / 3600

        guard elapsedHours >= 0.1 else {
            saveCurrentState(now: now)
            return
        }

        guard !isDead else {
            lastTimeMessage = "花は枯れてしまいました"
            saveCurrentState(now: now)
            return
        }

        let simulatedHours = min(elapsedHours, 168)
        let simulatedStart = now.addingTimeInterval(-simulatedHours * 3600)
        applyOfflineGrowthAndDecay(from: simulatedStart, to: now)

        lastTimeMessage = elapsedMessage(for: elapsedHours)
        saveCurrentState(now: now)
    }

    private func applyOfflineGrowthAndDecay(from start: Date, to end: Date) {
        var current = start

        while current < end {
            let next = min(current.addingTimeInterval(3600), end)
            let hours = next.timeIntervalSince(current) / 3600
            let daytimeHours = isDaytime(at: current) ? hours : 0
            let nighttimeHours = isDaytime(at: current) ? 0 : hours

            if hasPoorCondition {
                flower.mood = clamped(flower.mood - hours * 1.0)
            } else {
                // 条件が良い時間は、アプリを閉じていても少しずつ成長します。
                // 最高条件を保てた場合、開花まで最短約20日が目安です。
                growIfConditionsAreGood(baseAmount: hours * 0.167)
                flower.mood = clamped(flower.mood - hours * 0.15)
            }

            applyHourlyWeatherEffect(
                weather: flower.selectedWeather,
                daytimeHours: daytimeHours,
                nighttimeHours: nighttimeHours,
                humidity: flower.lastHumidity,
                windSpeed: flower.lastWindSpeed
            )

            // 栄養は天気に関係なく少しずつ消費されます。
            flower.nutrition = clamped(flower.nutrition - hours * 0.25)
            updateStressFromCurrentCondition(hours: hours)

            current = next
        }
    }

    private func applyHourlyWeatherEffect(
        weather: WeatherType,
        daytimeHours: Double,
        nighttimeHours: Double,
        humidity: Double?,
        windSpeed: Double?
    ) {
        let totalHours = daytimeHours + nighttimeHours

        switch weather {
        case .sunny:
            // 晴れは日光が増えますが、土は少し乾きやすくなります。
            flower.sunlight = clamped(flower.sunlight + daytimeHours * 1.4 - nighttimeHours * 0.15)
            flower.water = clamped(flower.water - daytimeHours * 0.5 - nighttimeHours * 0.2)
            flower.mood = clamped(flower.mood + daytimeHours * 0.12 - nighttimeHours * 0.03)
        case .cloudy:
            // 曇りが続くと日光不足になり、成長しづらくなります。
            flower.sunlight = clamped(flower.sunlight - daytimeHours * 1.0 - nighttimeHours * 0.15)
            flower.water = clamped(flower.water - daytimeHours * 0.2 - nighttimeHours * 0.18)
            flower.mood = clamped(flower.mood - daytimeHours * 0.08 - nighttimeHours * 0.04)
        case .rainy:
            // 雨は水分が増える代わりに、日光が落ちます。降りすぎると根腐れリスクも出ます。
            flower.water = clamped(flower.water + daytimeHours * 1.2 - nighttimeHours * 0.08)
            flower.sunlight = clamped(flower.sunlight - daytimeHours * 1.2 - nighttimeHours * 0.15)
            flower.mood = clamped(flower.mood - daytimeHours * 0.05 - nighttimeHours * 0.04)
        case .stormy:
            // 嵐は水分過多・日光不足・ストレス増加が重なりやすい危険な天気です。
            flower.water = clamped(flower.water + daytimeHours * 1.6 - nighttimeHours * 0.05)
            flower.sunlight = clamped(flower.sunlight - daytimeHours * 1.8 - nighttimeHours * 0.2)
            flower.mood = clamped(flower.mood - daytimeHours * 1.0 - nighttimeHours * 0.8)
        case .windy:
            // 強風は土が乾きやすく、花にも負担がかかります。
            flower.water = clamped(flower.water - daytimeHours * 0.9 - nighttimeHours * 0.45)
            flower.sunlight = clamped(flower.sunlight - daytimeHours * 0.5 - nighttimeHours * 0.15)
            flower.mood = clamped(flower.mood - daytimeHours * 0.75 - nighttimeHours * 0.55)
        }

        applyHourlyHumidityEffect(humidity: humidity, hours: totalHours)
        applyHourlyWindEffect(windSpeed: windSpeed, hours: totalHours)
    }

    private func applyHourlyHumidityEffect(humidity: Double?, hours: Double) {
        guard let humidity else {
            return
        }

        switch humidity {
        case ..<35:
            // 乾燥している日は水分が少し抜けやすく、花にも軽い負担がかかります。
            flower.water = clamped(flower.water - hours * 0.28)
            flower.mood = clamped(flower.mood - hours * 0.05)
        case ..<45:
            flower.water = clamped(flower.water - hours * 0.14)
        case 80..<90:
            flower.water = clamped(flower.water + hours * 0.12)
        case 90...:
            // 湿度が高すぎると土が乾きにくく、蒸れによるストレスも少し出ます。
            flower.water = clamped(flower.water + hours * 0.22)
            flower.mood = clamped(flower.mood - hours * 0.05)
        default:
            break
        }
    }

    private func applyHourlyWindEffect(windSpeed: Double?, hours: Double) {
        guard let windSpeed else {
            return
        }

        switch windSpeed {
        case 35...:
            // かなり強い風は水分を奪いやすく、花の負担も大きくなります。
            flower.water = clamped(flower.water - hours * 0.45)
            flower.mood = clamped(flower.mood - hours * 0.28)
        case 24..<35:
            flower.water = clamped(flower.water - hours * 0.28)
            flower.mood = clamped(flower.mood - hours * 0.14)
        case 14..<24:
            flower.water = clamped(flower.water - hours * 0.12)
        default:
            break
        }
    }

    private func weatherElapsedHours(from start: Date, to end: Date) -> (daytime: Double, nighttime: Double) {
        var current = start
        var daytime: Double = 0
        var nighttime: Double = 0

        while current < end {
            let next = min(current.addingTimeInterval(1800), end)
            let hours = next.timeIntervalSince(current) / 3600

            if isDaytime(at: current) {
                daytime += hours
            } else {
                nighttime += hours
            }

            current = next
        }

        return (daytime, nighttime)
    }

    private func isDaytime(at date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 6 && hour < 18
    }

    private func growIfConditionsAreGood(baseAmount: Double, action: CareAction? = nil) {
        // しおれ・枯れ状態ではまず回復を優先し、成長は止めます。
        guard !isWilted, !isDead else {
            return
        }

        let conditionMultiplier = growthConditionMultiplier()

        guard conditionMultiplier > 0 else {
            return
        }

        let actionMultiplier = growthActionMultiplier(for: action)
        flower.growth = clamped(flower.growth + baseAmount * conditionMultiplier * actionMultiplier)
    }

    private func growthConditionMultiplier() -> Double {
        guard flower.water >= 35,
              flower.water <= 96,
              flower.sunlight >= 38,
              flower.sunlight <= 96,
              flower.nutrition >= 38,
              flower.nutrition <= 96,
              flower.mood >= 45,
              stressPercent < 36 else {
            return 0
        }

        let waterScore = rangeScore(flower.water, ideal: 58...84, viable: 35...96)
        let sunlightScore = rangeScore(flower.sunlight, ideal: 58...88, viable: 38...96)
        let nutritionScore = rangeScore(flower.nutrition, ideal: 58...86, viable: 38...96)
        let moodScore = rangeScore(flower.mood, ideal: 68...100, viable: 45...100)

        let coreScore = waterScore * 0.30 + sunlightScore * 0.30 + nutritionScore * 0.25 + moodScore * 0.15

        guard coreScore >= 0.42 else {
            return 0
        }

        let stressPenalty = 1 - min(stressPercent / 42, 0.75)
        return coreScore * weatherGrowthMultiplier() * stressPenalty
    }

    private func growthActionMultiplier(for action: CareAction?) -> Double {
        guard let action else {
            return 1
        }

        switch action {
        case .water:
            let dryWeatherBonus = (flower.selectedWeather == .sunny || flower.selectedWeather == .windy) ? 1.08 : 1.0
            return rangeScore(flower.water, ideal: 58...82, viable: 35...94) * dryWeatherBonus
        case .sunlight:
            let lightWeatherBonus = (flower.selectedWeather == .sunny || flower.selectedWeather == .cloudy) ? 1.08 : 0.92
            let daytimeBonus = isCurrentWeatherDaytime ? 1.0 : 0.82
            return rangeScore(flower.sunlight, ideal: 60...90, viable: 38...96) * lightWeatherBonus * daytimeBonus
        case .fertilizer:
            return rangeScore(flower.nutrition, ideal: 60...84, viable: 38...94)
        }
    }

    private func weatherGrowthMultiplier() -> Double {
        var multiplier: Double

        switch flower.selectedWeather {
        case .sunny:
            multiplier = isCurrentWeatherDaytime ? 1.18 : 0.88
        case .cloudy:
            multiplier = 0.90
        case .rainy:
            multiplier = 0.78
        case .stormy:
            multiplier = 0.42
        case .windy:
            multiplier = 0.68
        }

        if let humidity = flower.lastHumidity {
            switch humidity {
            case ..<35:
                multiplier *= 0.84
            case 45...78:
                multiplier *= 1.06
            case 90...:
                multiplier *= 0.82
            default:
                break
            }
        }

        if let windSpeed = flower.lastWindSpeed {
            switch windSpeed {
            case 35...:
                multiplier *= 0.72
            case 24..<35:
                multiplier *= 0.84
            default:
                break
            }
        }

        if let precipitation = flower.lastPrecipitation, precipitation >= 5 {
            multiplier *= precipitation >= 18 ? 0.76 : 0.90
        }

        return multiplier
    }

    private func rangeScore(_ value: Double, ideal: ClosedRange<Double>, viable: ClosedRange<Double>) -> Double {
        guard viable.contains(value) else {
            return 0
        }

        let center = (ideal.lowerBound + ideal.upperBound) / 2
        let idealHalfWidth = max((ideal.upperBound - ideal.lowerBound) / 2, 1)

        if ideal.contains(value) {
            let distanceFromCenter = abs(value - center)
            return 1 - (distanceFromCenter / idealHalfWidth) * 0.16
        }

        if value < ideal.lowerBound {
            let recoverableWidth = max(ideal.lowerBound - viable.lowerBound, 1)
            return max(0, 0.18 + 0.66 * ((value - viable.lowerBound) / recoverableWidth))
        }

        let recoverableWidth = max(viable.upperBound - ideal.upperBound, 1)
        return max(0, 0.18 + 0.66 * ((viable.upperBound - value) / recoverableWidth))
    }

    private func saveCurrentState(now: Date = Date()) {
        flower.lastOpenedAt = now
        storageService.saveFlower(flower)
        scheduleNotificationsForCurrentState()
    }

    private func scheduleNotificationsForCurrentState() {
        LocalNotificationService.shared.scheduleReminders(
            for: flower,
            stressPercent: stressPercent,
            deathRiskPercent: deathRiskPercent,
            isWilted: isWilted,
            isDead: isDead,
            canWaterToday: canWaterToday,
            canGiveSunlightToday: canGiveSunlightToday,
            canFeedToday: canFeedToday
        )
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    private func statusColor(for statusText: String?) -> Color {
        switch statusText {
        case "危険":
            return .red
        case "多い", "高い", "注意":
            return .orange
        case "少ない":
            return .yellow
        default:
            return .green
        }
    }

    private var displayGrowthPercent: Int {
        let growth = clamped(flower.growth)

        if growth > 0, growth < 1 {
            return 1
        }

        return Int(growth.rounded(.down))
    }

    private var currentStressHours: Double {
        flower.stressHours ?? 0
    }

    private var currentFatalStressHours: Double {
        flower.fatalStressHours ?? 0
    }

    private var currentCareStreak: Int {
        guard let lastCareDate = flower.lastCareDate else {
            return 0
        }

        if isDateInToday(lastCareDate) || isDateInYesterday(lastCareDate) {
            return flower.careStreak ?? 0
        }

        return 0
    }

    private var hasPoorCondition: Bool {
        conditionStressScore >= 1.0
    }

    private var hasGoodRecoveryCondition: Bool {
        flower.water >= 55 && flower.water <= 88 &&
        flower.sunlight >= 52 && flower.sunlight <= 92 &&
        flower.nutrition >= 55 && flower.nutrition <= 90 &&
        flower.mood >= 50
    }

    private var conditionStressScore: Double {
        var score: Double = 0

        switch flower.water {
        case 98...:
            // 水が多すぎる状態が続くと根腐れリスクが高くなります。
            score += 2.2
        case 95...:
            score += 1.45
        case 90...:
            score += 0.8
        case ..<10:
            score += 2.2
        case ..<20:
            score += 1.4
        case ..<35:
            score += 0.7
        default:
            break
        }

        switch flower.sunlight {
        case ..<10:
            score += 1.7
        case ..<25:
            score += 1.1
        case ..<40:
            score += 0.45
        case 96...:
            score += 0.35
        default:
            break
        }

        switch flower.nutrition {
        case 98...:
            // 肥料が多すぎる状態が続くと肥料焼けで弱りやすくなります。
            score += 2.0
        case 95...:
            score += 1.35
        case 92...:
            score += 0.75
        case ..<10:
            score += 1.9
        case ..<25:
            score += 1.2
        case ..<40:
            score += 0.5
        default:
            break
        }

        switch flower.mood {
        case ..<15:
            score += 1.2
        case ..<30:
            score += 0.75
        case ..<45:
            score += 0.3
        default:
            break
        }

        return score
    }

    private func updateStressFromCurrentCondition(hours: Double) {
        guard !isDead else {
            return
        }

        let score = conditionStressScore

        if score >= 1.0 {
            flower.stressHours = currentStressHours + hours * score

            if currentStressHours >= 24 {
                flower.fatalStressHours = currentFatalStressHours + hours * fatalStressRate(for: score)
            } else {
                reduceFatalStress(by: hours * 0.35)
            }
        } else if hasGoodRecoveryCondition {
            recoverFromCare(stressHours: hours * 1.8, fatalHours: hours * 1.1)
        } else {
            reduceStress(by: hours * 0.35)
            reduceFatalStress(by: hours * 0.15)
        }
    }

    private func reduceStress(by hours: Double) {
        flower.stressHours = max(0, currentStressHours - hours)
    }

    private func reduceFatalStress(by hours: Double) {
        flower.fatalStressHours = max(0, currentFatalStressHours - hours)
    }

    private func recoverFromCare(stressHours: Double, fatalHours: Double) {
        reduceStress(by: stressHours)
        reduceFatalStress(by: fatalHours)
    }

    private func recordCareForToday(now: Date = Date()) {
        if let lastCareDate = flower.lastCareDate {
            if isSameCareDay(lastCareDate, now) {
                return
            }

            if isPreviousCareDay(lastCareDate, now) {
                flower.careStreak = (flower.careStreak ?? 0) + 1
            } else {
                flower.careStreak = 1
            }
        } else {
            flower.careStreak = 1
        }

        flower.lastCareDate = now
    }

    private func fatalStressRate(for score: Double) -> Double {
        if score >= 5.0 {
            return 1.45
        } else if score >= 3.5 {
            return 1.05
        } else if score >= 2.4 {
            return 0.65
        } else {
            return 0.25
        }
    }

    private func hasUsedToday(_ date: Date?) -> Bool {
        guard let date else {
            return false
        }

        return isDateInToday(date)
    }

    private func isDateInToday(_ date: Date, now: Date = Date()) -> Bool {
        isSameCareDay(date, now)
    }

    private func isDateInYesterday(_ date: Date, now: Date = Date()) -> Bool {
        isPreviousCareDay(date, now)
    }

    private func isSameCareDay(_ lhs: Date, _ rhs: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: lhs) == calendar.startOfDay(for: rhs)
    }

    private func isPreviousCareDay(_ date: Date, _ now: Date) -> Bool {
        let calendar = Calendar.current
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) else {
            return false
        }

        return calendar.startOfDay(for: date) == yesterdayStart
    }

    private func scheduleMidnightRefresh() {
        midnightRefreshTask?.cancel()
        midnightRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                let now = Date()
                let nextRefresh = self.nextMidnightRefreshDate(after: now)
                let waitSeconds = max(1, nextRefresh.timeIntervalSince(now))

                try? await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    self.objectWillChange.send()
                    self.scheduleNotificationsForCurrentState()
                }
            }
        }
    }

    private func nextMidnightRefreshDate(after date: Date) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(24 * 60 * 60)
    }

    private func plantStageNumber(for growth: Double) -> Int {
        let stageNumber = Int((growth / 100 * 9).rounded()) + 1
        return min(max(stageNumber, 1), 10)
    }

    private func elapsedMessage(for hours: Double) -> String {
        if hours < 1 {
            return "少し時間が経ちました"
        } else if hours < 24 {
            return "\(Int(hours))時間ぶりに花の様子を見ました"
        } else {
            return "\(Int(hours / 24))日ぶりに花の様子を見ました"
        }
    }
}
