import Foundation
import SwiftUI

/// 花の状態管理と育成ロジックをまとめるViewModelです。
/// ViewはこのViewModelの値を表示し、ボタン操作をViewModelへ伝えるだけにします。
@MainActor
final class FlowerGardenViewModel: ObservableObject {
    @Published private(set) var flower: FlowerState
    @Published var selectedWeather: WeatherType
    @Published private(set) var lastTimeMessage: String = "今日も少しずつ育てましょう"
    @Published private(set) var currentTemperature: Double?
    @Published private(set) var currentHumidity: Double?
    @Published private(set) var currentWindSpeed: Double?
    @Published private(set) var isCurrentWeatherDaytime: Bool = true

    private let storageService: FlowerStorageServicing
    private let weatherService: WeatherServicing
    private let locationService: LocationService
    private var isRefreshingRealWeather = false

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

        applyOfflineProgressIfNeeded()

        Task {
            await refreshRealWeather()
        }
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

        return String(format: "growth_stage_%02d", stageNumber)
    }

    var growthPercentText: String {
        "\(Int(flower.growth))%"
    }

    var visualStageProgressPercent: Double {
        let stageNumber = plantStageNumber(for: flower.growth)

        guard stageNumber < 10 else {
            return 100
        }

        let lowerBoundary = visualStageLowerBoundary(for: stageNumber)
        let upperBoundary = visualStageLowerBoundary(for: stageNumber + 1)
        let progress = (flower.growth - lowerBoundary) / (upperBoundary - lowerBoundary) * 100

        return clamped(progress)
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

        if currentFatalStressHours >= 24 {
            return "危険な状態が続いています。まず水分・日光・栄養を適正に戻しましょう"
        }

        if isWilted {
            return "しおれています。良い状態を保つと少しずつ回復します"
        }

        if flower.water >= 96 {
            return "水分が多すぎます。根腐れしやすい状態です"
        }

        if flower.nutrition >= 96 {
            return "栄養が多すぎます。肥料焼けに注意してください"
        }

        if flower.water < 20 {
            return "水分がかなり不足しています。乾燥で弱りやすい状態です"
        }

        if flower.sunlight < 42 {
            return "日光不足で成長が止まっています"
        }

        if flower.sunlight < 55 {
            return "日光不足で成長がかなり遅くなっています"
        }

        if flower.nutrition < 25 {
            return "栄養不足で成長しにくくなっています"
        }

        if deathRiskPercent >= 45 {
            return "枯れリスクが高めです。過不足のあるゲージを整えましょう"
        }

        if stressPercent >= 28 {
            return "ストレスが高く、成長が止まっています"
        }

        if flower.selectedWeather == .stormy {
            return "嵐の影響でストレスが溜まりやすい天気です"
        }

        if flower.selectedWeather == .windy || (flower.lastWindSpeed ?? 0) >= 24 {
            return "風が強く、水分が抜けやすい状態です"
        }

        if let humidity = flower.lastHumidity {
            if humidity < 35 {
                return "空気が乾燥していて、水分が減りやすい状態です"
            }

            if humidity >= 90 {
                return "湿度が高く、土が乾きにくい状態です"
            }
        }

        if !isCurrentWeatherDaytime {
            return "夜の間は日光が増えません"
        }

        return "育成環境は安定しています"
    }

    var careAdviceSystemImage: String {
        if isDead {
            return "xmark.circle.fill"
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

        if isWilted || stressPercent >= 28 || flower.water >= 96 || flower.nutrition >= 96 {
            return .orange
        }

        if flower.sunlight < 55 || flower.water < 20 || flower.nutrition < 25 {
            return .yellow
        }

        return .green
    }

    func waterFlower() {
        guard canWaterToday, !isDead else {
            return
        }

        flower.water = clamped(flower.water + 18)
        flower.mood = clamped(flower.mood + 6)
        flower.lastWateredAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 8, fatalHours: 4)
        growIfConditionsAreGood(baseAmount: 0.45)
        saveCurrentState()
    }

    func giveSunlight() {
        guard canGiveSunlightToday, !isDead else {
            return
        }

        flower.sunlight = clamped(flower.sunlight + 18)
        flower.water = clamped(flower.water - 5)
        flower.mood = clamped(flower.mood + 4)
        flower.lastSunlightAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 6, fatalHours: 3)
        growIfConditionsAreGood(baseAmount: 0.70)
        saveCurrentState()
    }

    func feedFlower() {
        guard canFeedToday, !isDead else {
            return
        }

        flower.nutrition = clamped(flower.nutrition + 20)
        flower.mood = clamped(flower.mood + 4)
        flower.lastFedAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 9, fatalHours: 4)
        growIfConditionsAreGood(baseAmount: 0.55)
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
            isCurrentWeatherDaytime = currentWeather.isDay
            selectedWeather = currentWeather.type
            flower.selectedWeather = currentWeather.type
            flower.lastHumidity = currentWeather.humidity
            flower.lastWindSpeed = currentWeather.windSpeed

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

    func forceWiltForTesting() {
        // 0%は鉢だけなので、しおれ画像を確認できる最低限の成長度まで進めます。
        flower.growth = max(flower.growth, 12)
        flower.water = min(flower.water, 12)
        flower.sunlight = min(flower.sunlight, 12)
        flower.nutrition = min(flower.nutrition, 12)
        flower.mood = min(flower.mood, 18)
        flower.stressHours = 24
        flower.fatalStressHours = 0
        saveCurrentState()
    }

    func forceDeadForTesting() {
        // 0%は鉢だけなので、枯れ画像を確認できる最低限の成長度まで進めます。
        flower.growth = max(flower.growth, 12)
        flower.water = min(flower.water, 5)
        flower.sunlight = min(flower.sunlight, 8)
        flower.nutrition = min(flower.nutrition, 5)
        flower.mood = min(flower.mood, 8)
        flower.stressHours = 96
        flower.fatalStressHours = 48
        saveCurrentState()
    }

    func forceGrowForTesting() {
        flower.growth = clamped(flower.growth + 11)
        flower.water = max(flower.water, 60)
        flower.sunlight = max(flower.sunlight, 60)
        flower.nutrition = max(flower.nutrition, 60)
        flower.mood = max(flower.mood, 70)
        flower.stressHours = 0
        flower.fatalStressHours = 0
        saveCurrentState()
    }

    func resetTestState() {
        flower = FlowerState.initial
        selectedWeather = flower.selectedWeather
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
        let weatherHours = weatherElapsedHours(from: simulatedStart, to: now)

        // アプリを閉じている間も、直近で取得した現実の天気に合わせて状態を変化させます。
        applyHourlyWeatherEffect(
            weather: flower.selectedWeather,
            daytimeHours: weatherHours.daytime,
            nighttimeHours: weatherHours.nighttime,
            humidity: flower.lastHumidity,
            windSpeed: flower.lastWindSpeed
        )

        // 栄養は天気に関係なく少しずつ消費されます。
        flower.nutrition = clamped(flower.nutrition - simulatedHours * 0.25)

        updateStressFromCurrentCondition(hours: simulatedHours)

        if hasPoorCondition {
            flower.mood = clamped(flower.mood - simulatedHours * 1.0)
        } else {
            // 状態が良くても、放置中は少しずつ寂しさが溜まる想定です。
            flower.mood = clamped(flower.mood - simulatedHours * 0.15)
            growIfConditionsAreGood(baseAmount: simulatedHours * 0.055)
        }

        lastTimeMessage = elapsedMessage(for: elapsedHours)
        saveCurrentState(now: now)
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

    private func growIfConditionsAreGood(baseAmount: Double) {
        // しおれ・枯れ状態ではまず回復を優先し、成長は止めます。
        guard !isWilted, !isDead else {
            return
        }

        guard flower.water >= 55,
              flower.water <= 90,
              flower.sunlight >= 42,
              flower.sunlight <= 94,
              flower.nutrition >= 55,
              flower.nutrition <= 94,
              flower.mood >= 55,
              stressPercent < 28 else {
            return
        }

        let averageCondition = (flower.water + flower.sunlight + flower.nutrition + flower.mood) / 4
        let sunlightGrowthRate: Double

        if flower.sunlight >= 55 {
            sunlightGrowthRate = 1.0
        } else if flower.sunlight >= 48 {
            sunlightGrowthRate = 0.35
        } else {
            sunlightGrowthRate = 0.18
        }

        guard averageCondition >= 64 else {
            return
        }

        let bonus: Double
        if averageCondition >= 88 {
            bonus = 1.25
        } else if averageCondition >= 78 {
            bonus = 1.08
        } else if averageCondition >= 68 {
            bonus = 0.65
        } else {
            bonus = 0.35
        }

        flower.growth = clamped(flower.growth + baseAmount * bonus * sunlightGrowthRate)
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

        if Calendar.current.isDateInToday(lastCareDate) || Calendar.current.isDateInYesterday(lastCareDate) {
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
        let calendar = Calendar.current

        if let lastCareDate = flower.lastCareDate {
            if calendar.isDateInToday(lastCareDate) {
                return
            }

            if calendar.isDateInYesterday(lastCareDate) {
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

        return Calendar.current.isDateInToday(date)
    }

    private func plantStageNumber(for growth: Double) -> Int {
        let stageNumber = Int((growth / 100 * 9).rounded()) + 1
        return min(max(stageNumber, 1), 10)
    }

    private func visualStageLowerBoundary(for stageNumber: Int) -> Double {
        if stageNumber <= 1 {
            return 0
        }

        if stageNumber >= 10 {
            return 100
        }

        // 画像段階はroundで切り替えているため、段階の境目は各中心値の中間になります。
        return (Double(stageNumber) - 1.5) / 9 * 100
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
