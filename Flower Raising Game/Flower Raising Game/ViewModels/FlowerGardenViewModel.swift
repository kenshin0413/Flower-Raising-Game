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
    @Published private(set) var bloomRecords: [PlantBloomRecord]
    @Published private(set) var storedGachaPlantIDs: Set<String>
    @Published private(set) var storedGachaVaseIDs: Set<String>
    @Published private(set) var gachaTicketCount: Int
    @Published private(set) var isDailyGachaTicketRewardPresented = false
    @Published private(set) var isBloomBonusRewardPresented = false

    private let storageService: FlowerStorageServicing
    private let encyclopediaStorageService: PlantEncyclopediaStorageServicing
    private let weatherService: WeatherServicing
    private let locationService: LocationService
    private var isRefreshingRealWeather = false
    private var midnightRefreshTask: Task<Void, Never>?
    private let storedGachaPlantIDsKey = "stored_gacha_plant_ids_v1"
    private let storedGachaVaseIDsKey = "stored_gacha_vase_ids_v1"
    private let migratedLegacyGachaVaseIDsKey = "migrated_legacy_gacha_vase_ids_v1"
    private let repairedLegacyGachaVaseIDsKey = "repaired_legacy_gacha_vase_ids_v2"
    private let gachaTicketCountKey = "gacha_ticket_count_v1"
    private let lastGachaTicketGrantedAtKey = "last_gacha_ticket_granted_at_v1"
    private let rewardedAdPromptSeenKey = "rewarded_ad_prompt_seen_v1"
    private let rewardedWaterUsedAtKey = "rewarded_water_used_at_v1"
    private let rewardedSunlightUsedAtKey = "rewarded_sunlight_used_at_v1"
    private let rewardedFertilizerUsedAtKey = "rewarded_fertilizer_used_at_v1"
    private let rewardedGachaTicketGrantedAtKey = "rewarded_gacha_ticket_granted_at_v1"
    private let roseSunlightUnlockCountKey = "rose_sunlight_unlock_count_v1"
    private let roseSunlightUnlockRequirement = 5
    private let freeSeedGachaUsedKey = "free_seed_gacha_used_v1"
    private let freeVaseGachaUsedKey = "free_vase_gacha_used_v1"
    private let gachaTicketCost = 10
    private let initialUnlockedVaseIDs: Set<String> = [VaseStyleCatalog.defaultVaseID, "terracotta"]

    init(
        storageService: FlowerStorageServicing = FlowerStorageService(),
        encyclopediaStorageService: PlantEncyclopediaStorageServicing = PlantEncyclopediaStorageService(),
        weatherService: WeatherServicing = OpenMeteoWeatherService(),
        locationService: LocationService = LocationService()
    ) {
        self.storageService = storageService
        self.encyclopediaStorageService = encyclopediaStorageService
        self.weatherService = weatherService
        self.locationService = locationService

        var savedFlower = storageService.loadFlower() ?? FlowerState.initial
        savedFlower.plantedAt = savedFlower.plantedAt ?? savedFlower.lastOpenedAt
        savedFlower.vaseID = savedFlower.vaseID ?? VaseStyleCatalog.defaultVaseID
        savedFlower.openedDayCount = max(savedFlower.openedDayCount ?? 1, 1)
        savedFlower.lastOpenedDayCountedAt = savedFlower.lastOpenedDayCountedAt ?? savedFlower.lastOpenedAt
        let loadedBloomRecords = encyclopediaStorageService.loadRecords()
        self.flower = savedFlower
        self.bloomRecords = loadedBloomRecords
        var storedPlantIDs = Self.loadStoredIDs(
            key: storedGachaPlantIDsKey,
            fallback: Set([PlantSpeciesCatalog.defaultPlantID])
        )
        self.storedGachaPlantIDs = storedPlantIDs
        var storedVaseIDs = Self.loadStoredIDs(
            key: storedGachaVaseIDsKey,
            fallback: initialUnlockedVaseIDs
        )
        storedVaseIDs.formUnion(initialUnlockedVaseIDs)
        if UserDefaults.standard.bool(forKey: migratedLegacyGachaVaseIDsKey),
           !UserDefaults.standard.bool(forKey: repairedLegacyGachaVaseIDsKey) {
            storedVaseIDs = initialUnlockedVaseIDs
            UserDefaults.standard.set(true, forKey: repairedLegacyGachaVaseIDsKey)
        }
        self.storedGachaVaseIDs = storedVaseIDs
        self.gachaTicketCount = UserDefaults.standard.integer(forKey: gachaTicketCountKey)
        UserDefaults.standard.set(Array(storedPlantIDs).sorted(), forKey: storedGachaPlantIDsKey)
        UserDefaults.standard.set(Array(storedVaseIDs).sorted(), forKey: storedGachaVaseIDsKey)
        self.selectedWeather = savedFlower.selectedWeather
        self.currentHumidity = savedFlower.lastHumidity
        self.currentWindSpeed = savedFlower.lastWindSpeed
        self.currentPrecipitation = savedFlower.lastPrecipitation

        if !isVaseUnlocked(selectedVaseStyle) {
            flower.vaseID = VaseStyleCatalog.defaultVaseID
            UserDefaults.standard.set(Array(storedGachaVaseIDs).sorted(), forKey: storedGachaVaseIDsKey)
            storageService.saveFlower(flower)
        }

        if self.flower.growth >= 100, self.flower.bloomRecordedAt == nil {
            recordBloomIfNeeded()
        }
        if self.flower.growth >= 100,
           self.flower.bloomRecordedAt != nil,
           self.flower.bloomBonusResolvedAt == nil {
            self.isBloomBonusRewardPresented = true
        }

        applyOfflineProgressIfNeeded()

        Task {
            await refreshRealWeather()
        }

        recordAppOpenedToday()
        scheduleMidnightRefresh()
    }

    deinit {
        midnightRefreshTask?.cancel()
    }

    private static func loadStoredIDs(key: String, fallback: Set<String>) -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: key) ?? []
        return fallback.union(stored)
    }

    private func saveStoredIDs(_ ids: Set<String>, key: String) {
        UserDefaults.standard.set(Array(ids).sorted(), forKey: key)
    }

    private func hasUsedRewardedCareToday(key: String) -> Bool {
        guard let usedAt = UserDefaults.standard.object(forKey: key) as? Date else {
            return false
        }

        return isDateInToday(usedAt)
    }

    var stageName: String {
        return flower.growthStage.displayName
    }

    var flowerEmoji: String {
        flower.growthStage.emoji
    }

    var plantImageName: String? {
        let stageNumber = plantStageNumber(for: flower.growth)
        return selectedPlantSpecies.imageName(
            for: stageNumber,
            isWilted: isWilted,
            isDead: isDead
        )
    }

    var availablePlantSpecies: [PlantSpecies] {
        PlantSpeciesCatalog.all
    }

    func isPlantUnlocked(_ plant: PlantSpecies) -> Bool {
        if storedGachaPlantIDs.contains(plant.id) {
            return true
        }

        if plant.id == "rose" {
            return roseSunlightUnlockCount >= roseSunlightUnlockRequirement
        }

        guard plant.id == "morning-glory" else {
            return plant.id == PlantSpeciesCatalog.defaultPlantID
        }

        return currentOpenedDayCount >= 10
    }

    var selectedPlantSpecies: PlantSpecies {
        PlantSpeciesCatalog.plant(for: flower.plantID)
    }

    var roseSunlightUnlockCount: Int {
        UserDefaults.standard.integer(forKey: roseSunlightUnlockCountKey)
    }

    var availableVaseStyles: [VaseStyle] {
        VaseStyleCatalog.all
    }

    var selectedVaseStyle: VaseStyle {
        VaseStyleCatalog.vase(for: flower.vaseID)
    }

    var waterIdealRange: ClosedRange<Double> {
        selectedPlantSpecies.preference.idealWater
    }

    var sunlightIdealRange: ClosedRange<Double> {
        selectedPlantSpecies.preference.idealSunlight
    }

    var nutritionIdealRange: ClosedRange<Double> {
        selectedPlantSpecies.preference.idealNutrition
    }

    var stressIdealRange: ClosedRange<Double> {
        0...max(18, selectedVaseStyle.effect.stressResistance >= 1.08 ? 30 : 27)
    }

    var pestDamageIdealRange: ClosedRange<Double> {
        0...24
    }

    var deathRiskIdealRange: ClosedRange<Double> {
        0...max(24, selectedVaseStyle.effect.stressResistance >= 1.08 ? 38 : 34)
    }

    var plantPreferenceSummaryText: String {
        selectedPlantSpecies.preference.summary
    }

    var vaseEffectSummaryText: String {
        selectedVaseStyle.effect.summary
    }

    func isVaseUnlocked(_ vase: VaseStyle) -> Bool {
        if storedGachaVaseIDs.contains(vase.id) {
            return true
        }

        if vase.id == "blue-gloss" {
            return currentOpenedDayCount >= 15
        }

        return false
    }

    var plantStageNumber: Int {
        plantStageNumber(for: flower.growth)
    }

    func selectVaseStyle(_ vase: VaseStyle) {
        guard isVaseUnlocked(vase) else {
            lastTimeMessage = vase.id == "blue-gloss"
                ? "青い陶器は15日間アプリを開くか、鉢箱で解放できます"
                : "\(vase.name)は鉢箱で解放できます"
            return
        }

        guard flower.vaseID != vase.id else {
            return
        }

        flower.vaseID = vase.id
        lastTimeMessage = "\(vase.name)に変更しました"
        saveCurrentState()
    }

    func storeGachaPlantResult(_ plant: PlantSpecies) {
        guard storedGachaPlantIDs.insert(plant.id).inserted else {
            return
        }

        saveStoredIDs(storedGachaPlantIDs, key: storedGachaPlantIDsKey)
        lastTimeMessage = "\(plant.name)を保管しました"
    }

    func storeGachaVaseResult(_ vase: VaseStyle) {
        guard storedGachaVaseIDs.insert(vase.id).inserted else {
            return
        }

        saveStoredIDs(storedGachaVaseIDs, key: storedGachaVaseIDsKey)
        lastTimeMessage = "\(vase.name)を保管しました"
    }

    var gachaTicketText: String {
        "\(gachaTicketCount)枚"
    }

    var gachaTicketCostText: String {
        "\(gachaTicketCost)枚"
    }

    var gachaTicketShortfallText: String {
        "\(max(gachaTicketCost - gachaTicketCount, 0))枚"
    }

    func isFirstGachaFree(isSeed: Bool) -> Bool {
        !UserDefaults.standard.bool(forKey: isSeed ? freeSeedGachaUsedKey : freeVaseGachaUsedKey)
    }

    var canWatchAdForGachaTicketToday: Bool {
        !hasUsedRewardedCareToday(key: rewardedGachaTicketGrantedAtKey)
    }

    var rewardedGachaTicketButtonTitle: String {
        canWatchAdForGachaTicketToday ? "広告を見てチケット+1" : "広告チケット受け取り済み"
    }

    var rewardedGachaTicketMessage: String {
        canWatchAdForGachaTicketToday
            ? "ログイン報酬とは別に、1日1枚だけ広告で受け取れます"
            : "広告チケットは明日0時にまた受け取れます"
    }

    func canOpenGacha(isSeed: Bool) -> Bool {
        isFirstGachaFree(isSeed: isSeed) || gachaTicketCount >= gachaTicketCost
    }

    func consumeGachaTicketsForDraw(isSeed: Bool) -> Bool {
        if isFirstGachaFree(isSeed: isSeed) {
            UserDefaults.standard.set(true, forKey: isSeed ? freeSeedGachaUsedKey : freeVaseGachaUsedKey)
            return true
        }

        guard canOpenGacha(isSeed: isSeed) else {
            lastTimeMessage = "チケットは\(gachaTicketCost)枚で1回開封できます"
            return false
        }

        gachaTicketCount -= gachaTicketCost
        UserDefaults.standard.set(gachaTicketCount, forKey: gachaTicketCountKey)
        return true
    }

    func grantRewardedGachaTicket() -> Bool {
        guard canWatchAdForGachaTicketToday else {
            lastTimeMessage = "広告チケットは今日は受け取り済みです"
            return false
        }

        gachaTicketCount += 1
        UserDefaults.standard.set(gachaTicketCount, forKey: gachaTicketCountKey)
        UserDefaults.standard.set(Date(), forKey: rewardedGachaTicketGrantedAtKey)
        lastTimeMessage = "広告でガチャチケットを1枚受け取りました"
        return true
    }

    func dismissBloomBonusReward() {
        guard isBloomBonusRewardPresented else {
            return
        }

        flower.bloomBonusResolvedAt = Date()
        isBloomBonusRewardPresented = false
        lastTimeMessage = "開花記念ボーナスは見送りました"
        saveCurrentState()
    }

    func grantBloomBonusReward() -> Bool {
        guard isBloomBonusRewardPresented,
              isFullyBloomed,
              flower.bloomRecordedAt != nil,
              flower.bloomBonusResolvedAt == nil else {
            return false
        }

        gachaTicketCount += 5
        UserDefaults.standard.set(gachaTicketCount, forKey: gachaTicketCountKey)
        flower.bloomBonusResolvedAt = Date()
        isBloomBonusRewardPresented = false
        lastTimeMessage = "開花記念でガチャチケットを5枚受け取りました"
        saveCurrentState()
        return true
    }

    func dismissDailyGachaTicketReward() {
        isDailyGachaTicketRewardPresented = false
    }

    func needsPlantChangeConfirmation(for plant: PlantSpecies) -> Bool {
        flower.plantID != plant.id && flower.growth >= 0.1 && !isDead && !isFullyBloomed
    }

    func selectPlantSpecies(_ plant: PlantSpecies) {
        guard isPlantUnlocked(plant) else {
            lastTimeMessage = lockedPlantMessage(for: plant)
            return
        }

        if isDead || isFullyBloomed {
            replaceCurrentPlantWithNewSeed(plant)
            return
        }

        guard flower.plantID != plant.id else {
            return
        }

        flower.plantID = plant.id
        lastTimeMessage = "\(plant.name)を育てます"
        saveCurrentState()
    }

    func replaceCurrentPlantWithNewSeed(_ plant: PlantSpecies) {
        guard isPlantUnlocked(plant) else {
            lastTimeMessage = lockedPlantMessage(for: plant)
            return
        }

        let selectedVaseID = flower.vaseID
        flower = FlowerState.initial
        flower.plantID = plant.id
        flower.vaseID = selectedVaseID ?? VaseStyleCatalog.defaultVaseID
        flower.plantedAt = Date()
        flower.bloomRecordedAt = nil
        selectedWeather = flower.selectedWeather
        lastTimeMessage = "\(plant.name)を育て始めました"
        saveCurrentState()
    }

    private func lockedPlantMessage(for plant: PlantSpecies) -> String {
        switch plant.id {
        case "rose":
            return "バラはライトを\(roseSunlightUnlockRequirement)回使うか、種袋で解放できます"
        case "morning-glory":
            return "朝顔は10日間アプリを開くか、種袋で解放できます"
        default:
            return "\(plant.name)は種袋で解放できます"
        }
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

    var pestDamagePercent: Double {
        clamped(flower.pestDamage ?? 0)
    }

    var deathRiskPercent: Double {
        if isDead {
            return 100
        }

        let conditionRisk = min(conditionStressScore / 6, 1) * 25
        let wiltRisk = min(currentStressHours / 24, 1) * 30
        let fatalRisk = min(currentFatalStressHours / 48, 1) * 70
        let pestRisk = max(pestDamagePercent - 55, 0) * 0.28
        let rawRisk = conditionRisk + fatalRisk + pestRisk + (currentStressHours >= 18 ? wiltRisk : wiltRisk * 0.35)

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
        false
    }

    var canFeedToday: Bool {
        !isDead && !hasUsedToday(flower.lastFedAt)
    }

    var shouldShowRewardedAdPrompt: Bool {
        !UserDefaults.standard.bool(forKey: rewardedAdPromptSeenKey)
    }

    var canWatchAdForWaterToday: Bool {
        !isDead && hasUsedToday(flower.lastWateredAt) && !hasUsedRewardedCareToday(key: rewardedWaterUsedAtKey)
    }

    var canWatchAdForSunlightToday: Bool {
        !isDead && !hasUsedRewardedCareToday(key: rewardedSunlightUsedAtKey)
    }

    var canWatchAdForFertilizerToday: Bool {
        !isDead && hasUsedToday(flower.lastFedAt) && !hasUsedRewardedCareToday(key: rewardedFertilizerUsedAtKey)
    }

    var canTapWaterAction: Bool {
        canWaterToday || canWatchAdForWaterToday
    }

    var canTapSunlightAction: Bool {
        canWatchAdForSunlightToday
    }

    var canTapFeedAction: Bool {
        canFeedToday || canWatchAdForFertilizerToday
    }

    var waterActionSubtitle: String {
        if canWaterToday {
            return "水分 +4.5%"
        }

        return canWatchAdForWaterToday ? "広告で+1回" : "今日は完了"
    }

    var sunlightActionSubtitle: String {
        canWatchAdForSunlightToday ? "広告で1回" : "今日は完了"
    }

    var feedActionSubtitle: String {
        if canFeedToday {
            return "栄養 +3.5%"
        }

        return canWatchAdForFertilizerToday ? "広告で+1回" : "今日は完了"
    }

    var isFullyBloomed: Bool {
        flower.growth >= 100
    }

    var careStreakText: String {
        "\(max(currentCareStreak, 1))日継続"
    }

    var isWilted: Bool {
        return !isDead && currentStressHours >= 24
    }

    var isDead: Bool {
        return currentFatalStressHours >= 48 || currentStressHours >= 96
    }

    var careAdviceText: String {
        if isDead {
            return "枯れてしまいました。植え替えて新しく育てましょう"
        }

        if isFullyBloomed {
            return "きれいに開花しました。植え替えると新しい花を育てられます"
        }

        if currentFatalStressHours >= 24 {
            return "危険です。\(selectedPlantSpecies.name)の好みに近い環境へ戻そう"
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
            if canWaterToday {
                return "水やりで水分\(Int(waterIdealRange.lowerBound))%以上へ。\(selectedPlantSpecies.name)は\(selectedPlantSpecies.preference.summary)"
            }

            return canWatchAdForWaterToday ? "広告を見ると今日もう一度だけ水やりできます" : "水分不足です。明日0時に水やりして\(Int(waterIdealRange.lowerBound))%以上へ"
        }

        if flower.sunlight < 42 {
            return canWatchAdForSunlightToday ? "広告を見ると今日一度だけライトを使えます" : "日光不足です。今日は水分と栄養を維持しよう"
        }

        if flower.sunlight < 55 {
            return canWatchAdForSunlightToday ? "日光\(Int(sunlightIdealRange.lowerBound))%以上が目標。広告ライトを使うと育ちやすいです" : "日光\(Int(sunlightIdealRange.lowerBound))%以上が目標。今日は水分と栄養を維持しよう"
        }

        if flower.nutrition < 25 {
            if canFeedToday {
                return "肥料で栄養\(Int(nutritionIdealRange.lowerBound))%以上へ。\(selectedVaseStyle.name)は\(selectedVaseStyle.effect.summary)"
            }

            return canWatchAdForFertilizerToday ? "広告を見ると今日もう一度だけ肥料をあげられます" : "栄養不足です。明日0時に肥料で\(Int(nutritionIdealRange.lowerBound))%以上へ"
        }

        if pestDamagePercent >= 55 {
            return "虫害が広がっています。水やり・ライト・肥料で状態を整えると少し落ち着きます"
        }

        if isPestRiskWeather {
            return "高温で虫が出やすい天気です。虫害ゲージが上がりすぎないように注意"
        }

        if deathRiskPercent >= 45 {
            return "枯れリスク高め。\(selectedPlantSpecies.name)の理想環境へ近づけよう"
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
            return canWatchAdForSunlightToday ? "夜は自然日光なし。広告ライトで55%以上を狙えます" : "夜は水分55-88%・栄養55-90%を維持しよう"
        }

        if selectedPlantSpecies.preference.preferredWeather.contains(flower.selectedWeather) {
            return "\(selectedPlantSpecies.name)向きの天気です。\(selectedPlantSpecies.preference.careHint)"
        }

        return "順調です。\(selectedPlantSpecies.preference.careHint)"
    }

    var careAdviceSystemImage: String {
        if isDead {
            return "xmark.circle.fill"
        }

        if isFullyBloomed {
            return "sparkles"
        }

        if pestDamagePercent >= 55 || isPestRiskWeather {
            return "ladybug.fill"
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

        if pestDamagePercent >= 55 {
            return .red
        }

        if isPestRiskWeather || pestDamagePercent >= 28 {
            return .orange
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
        let preference = selectedPlantSpecies.preference

        if flower.water > preference.viableWater.upperBound {
            return "危険"
        }

        if flower.water > preference.idealWater.upperBound {
            return "多い"
        }

        if flower.water < preference.viableWater.lowerBound {
            return "危険"
        }

        if flower.water < preference.idealWater.lowerBound {
            return "少ない"
        }

        return nil
    }

    var waterStatusColor: Color {
        statusColor(for: waterStatusText)
    }

    var sunlightStatusText: String? {
        let preference = selectedPlantSpecies.preference

        if flower.sunlight > preference.viableSunlight.upperBound {
            return "多い"
        }

        if flower.sunlight < preference.viableSunlight.lowerBound {
            return "危険"
        }

        if flower.sunlight < preference.idealSunlight.lowerBound {
            return "少ない"
        }

        return nil
    }

    var sunlightStatusColor: Color {
        statusColor(for: sunlightStatusText)
    }

    var nutritionStatusText: String? {
        let preference = selectedPlantSpecies.preference

        if flower.nutrition > preference.viableNutrition.upperBound {
            return "危険"
        }

        if flower.nutrition > preference.idealNutrition.upperBound {
            return "多い"
        }

        if flower.nutrition < preference.viableNutrition.lowerBound {
            return "危険"
        }

        if flower.nutrition < preference.idealNutrition.lowerBound {
            return "少ない"
        }

        return nil
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

    var pestDamageStatusText: String? {
        switch pestDamagePercent {
        case 60...:
            return "危険"
        case 30..<60:
            return "注意"
        default:
            return nil
        }
    }

    var pestDamageStatusColor: Color {
        statusColor(for: pestDamageStatusText)
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

        applyWaterCare()
    }

    func giveSunlight() {
        guard canGiveSunlightToday, !isDead else {
            return
        }

        applySunlightCare()
    }

    func feedFlower() {
        guard canFeedToday, !isDead else {
            return
        }

        applyFertilizerCare()
    }

    func markRewardedAdPromptSeen() {
        UserDefaults.standard.set(true, forKey: rewardedAdPromptSeenKey)
    }

    func applyRewardedWaterCare() {
        guard canWatchAdForWaterToday else {
            return
        }

        UserDefaults.standard.set(Date(), forKey: rewardedWaterUsedAtKey)
        applyWaterCare()
        lastTimeMessage = "広告ボーナスで水やりをもう1回しました"
    }

    func applyRewardedSunlightCare() {
        guard canWatchAdForSunlightToday else {
            return
        }

        UserDefaults.standard.set(Date(), forKey: rewardedSunlightUsedAtKey)
        let didUnlockRose = incrementRoseSunlightUnlockCount()
        applySunlightCare()
        lastTimeMessage = didUnlockRose
            ? "ライトを\(roseSunlightUnlockRequirement)回使ったのでバラが解放されました"
            : "広告ボーナスでライトを使いました"
    }

    private func incrementRoseSunlightUnlockCount() -> Bool {
        guard !storedGachaPlantIDs.contains("rose"),
              roseSunlightUnlockCount < roseSunlightUnlockRequirement else {
            return false
        }

        let nextCount = min(roseSunlightUnlockCount + 1, roseSunlightUnlockRequirement)
        UserDefaults.standard.set(nextCount, forKey: roseSunlightUnlockCountKey)

        return nextCount >= roseSunlightUnlockRequirement
    }

    func applyRewardedFertilizerCare() {
        guard canWatchAdForFertilizerToday else {
            return
        }

        UserDefaults.standard.set(Date(), forKey: rewardedFertilizerUsedAtKey)
        applyFertilizerCare()
        lastTimeMessage = "広告ボーナスで肥料をもう1回あげました"
    }

    func applyPlantTapBonus() {
        flower.water += 0.5
        flower.sunlight += 0.5
        flower.nutrition += 0.5
        saveCurrentState()
    }

    private func applyWaterCare() {
        flower.water = clamped(flower.water + 4.5 * selectedVaseStyle.effect.waterRetention)
        flower.mood = clamped(flower.mood + 6)
        flower.lastWateredAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 8, fatalHours: 4)
        growIfConditionsAreGood(baseAmount: 0.58, action: .water)
        saveCurrentState()
    }

    private func applySunlightCare() {
        flower.sunlight = clamped(flower.sunlight + 14 * selectedVaseStyle.effect.sunlightModifier)
        flower.water = clamped(flower.water - 5 / selectedVaseStyle.effect.waterRetention)
        flower.mood = clamped(flower.mood + 4)
        flower.lastSunlightAt = Date()
        recordCareForToday()
        recoverFromCare(stressHours: 6, fatalHours: 3)
        growIfConditionsAreGood(baseAmount: 0.66, action: .sunlight)
        saveCurrentState()
    }

    private func applyFertilizerCare() {
        flower.nutrition = clamped(flower.nutrition + 3.5 * selectedVaseStyle.effect.nutritionEfficiency)
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
        recordAppOpenedToday()
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
            flower.lastTemperature = currentWeather.temperature
            flower.lastHumidity = currentWeather.humidity
            flower.lastWindSpeed = currentWeather.windSpeed
            flower.lastPrecipitation = currentWeather.precipitation
            updatePestDamage(hours: 1, daytimeHours: currentWeather.isDay ? 1 : 0)

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
            applySunlightChange(22)
            applyWaterChange(-8)
            flower.mood = clamped(flower.mood + 6)
            growIfConditionsAreGood(baseAmount: 0.65)
        case .cloudy:
            applySunlightChange(8)
            applyWaterChange(-2)
            flower.mood = clamped(flower.mood + 1)
            growIfConditionsAreGood(baseAmount: 0.2)
        case .rainy:
            applyWaterChange(22)
            applySunlightChange(-5)
            flower.mood = clamped(flower.mood + 2)
            growIfConditionsAreGood(baseAmount: 0.3)
        case .stormy:
            applyWaterChange(12)
            applySunlightChange(-10)
            flower.mood = clamped(flower.mood - 18 / selectedVaseStyle.effect.stressResistance)
            growIfConditionsAreGood(baseAmount: 0.05)
        case .windy:
            applyWaterChange(-6)
            flower.mood = clamped(flower.mood - 10 / selectedVaseStyle.effect.stressResistance)
            growIfConditionsAreGood(baseAmount: 0.08)
        }

        updateStressFromCurrentCondition(hours: 3)
        updatePestDamage(hours: 3, daytimeHours: isCurrentWeatherDaytime ? 3 : 0)
    }

    func resetFlower() {
        let selectedPlantID = flower.plantID
        let selectedVaseID = flower.vaseID
        flower = FlowerState.initial
        flower.plantID = selectedPlantID ?? PlantSpeciesCatalog.defaultPlantID
        flower.vaseID = selectedVaseID ?? VaseStyleCatalog.defaultVaseID
        flower.plantedAt = Date()
        flower.bloomRecordedAt = nil
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
            flower.nutrition = clamped(flower.nutrition - hours * 0.25 / selectedVaseStyle.effect.nutritionEfficiency)
            updateStressFromCurrentCondition(hours: hours)
            updatePestDamage(hours: hours, daytimeHours: daytimeHours)

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
            applySunlightChange(daytimeHours * 1.4 - nighttimeHours * 0.15)
            applyWaterChange(-daytimeHours * 0.5 - nighttimeHours * 0.2)
            flower.mood = clamped(flower.mood + daytimeHours * 0.12 - nighttimeHours * 0.03)
        case .cloudy:
            // 曇りが続くと日光不足になり、成長しづらくなります。
            applySunlightChange(-daytimeHours * 1.0 - nighttimeHours * 0.15)
            applyWaterChange(-daytimeHours * 0.2 - nighttimeHours * 0.18)
            flower.mood = clamped(flower.mood - daytimeHours * 0.08 - nighttimeHours * 0.04)
        case .rainy:
            // 雨は水分が増える代わりに、日光が落ちます。降りすぎると根腐れリスクも出ます。
            applyWaterChange(daytimeHours * 1.2 - nighttimeHours * 0.08)
            applySunlightChange(-daytimeHours * 1.2 - nighttimeHours * 0.15)
            flower.mood = clamped(flower.mood - daytimeHours * 0.05 - nighttimeHours * 0.04)
        case .stormy:
            // 嵐は水分過多・日光不足・ストレス増加が重なりやすい危険な天気です。
            applyWaterChange(daytimeHours * 1.6 - nighttimeHours * 0.05)
            applySunlightChange(-daytimeHours * 1.8 - nighttimeHours * 0.2)
            flower.mood = clamped(flower.mood - (daytimeHours * 1.0 + nighttimeHours * 0.8) / selectedVaseStyle.effect.stressResistance)
        case .windy:
            // 強風は土が乾きやすく、花にも負担がかかります。
            applyWaterChange(-daytimeHours * 0.9 - nighttimeHours * 0.45)
            applySunlightChange(-daytimeHours * 0.5 - nighttimeHours * 0.15)
            flower.mood = clamped(flower.mood - (daytimeHours * 0.75 + nighttimeHours * 0.55) / selectedVaseStyle.effect.stressResistance)
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
            applyWaterChange(-hours * 0.28)
            flower.mood = clamped(flower.mood - hours * 0.05)
        case ..<45:
            applyWaterChange(-hours * 0.14)
        case 80..<90:
            applyWaterChange(hours * 0.12)
        case 90...:
            // 湿度が高すぎると土が乾きにくく、蒸れによるストレスも少し出ます。
            applyWaterChange(hours * 0.22)
            flower.mood = clamped(flower.mood - hours * 0.05 / selectedVaseStyle.effect.stressResistance)
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
            applyWaterChange(-hours * 0.45)
            flower.mood = clamped(flower.mood - hours * 0.28 / selectedVaseStyle.effect.stressResistance)
        case 24..<35:
            applyWaterChange(-hours * 0.28)
            flower.mood = clamped(flower.mood - hours * 0.14 / selectedVaseStyle.effect.stressResistance)
        case 14..<24:
            applyWaterChange(-hours * 0.12)
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
        let previousGrowth = flower.growth
        flower.growth = clamped(flower.growth + baseAmount * conditionMultiplier * actionMultiplier)

        if previousGrowth < 100, flower.growth >= 100 {
            recordBloomIfNeeded()
        }
    }

    private func growthConditionMultiplier() -> Double {
        let preference = selectedPlantSpecies.preference

        guard preference.viableWater.contains(flower.water),
              preference.viableSunlight.contains(flower.sunlight),
              preference.viableNutrition.contains(flower.nutrition),
              preference.viableMood.contains(flower.mood),
              pestDamagePercent < 72,
              stressPercent < 36 else {
            return 0
        }

        let waterScore = rangeScore(flower.water, ideal: preference.idealWater, viable: preference.viableWater)
        let sunlightScore = rangeScore(flower.sunlight, ideal: preference.idealSunlight, viable: preference.viableSunlight)
        let nutritionScore = rangeScore(flower.nutrition, ideal: preference.idealNutrition, viable: preference.viableNutrition)
        let moodScore = rangeScore(flower.mood, ideal: preference.idealMood, viable: preference.viableMood)

        let coreScore = waterScore * 0.30 + sunlightScore * 0.30 + nutritionScore * 0.25 + moodScore * 0.15

        guard coreScore >= 0.42 else {
            return 0
        }

        let stressPenalty = 1 - min(stressPercent / 42, 0.75)
        let pestPenalty = 1 - min(pestDamagePercent / 120, 0.55)
        return coreScore * weatherGrowthMultiplier() * selectedVaseStyle.effect.growthModifier * preference.growthBias * stressPenalty * pestPenalty
    }

    private func growthActionMultiplier(for action: CareAction?) -> Double {
        guard let action else {
            return 1
        }

        switch action {
        case .water:
            let dryWeatherBonus = (flower.selectedWeather == .sunny || flower.selectedWeather == .windy) ? 1.08 : 1.0
            return rangeScore(flower.water, ideal: selectedPlantSpecies.preference.idealWater, viable: selectedPlantSpecies.preference.viableWater) * dryWeatherBonus * careAffinityMultiplier(for: .water)
        case .sunlight:
            let lightWeatherBonus = (flower.selectedWeather == .sunny || flower.selectedWeather == .cloudy) ? 1.08 : 0.92
            let daytimeBonus = isCurrentWeatherDaytime ? 1.0 : 0.82
            return rangeScore(flower.sunlight, ideal: selectedPlantSpecies.preference.idealSunlight, viable: selectedPlantSpecies.preference.viableSunlight) * lightWeatherBonus * daytimeBonus * careAffinityMultiplier(for: .sunlight)
        case .fertilizer:
            return rangeScore(flower.nutrition, ideal: selectedPlantSpecies.preference.idealNutrition, viable: selectedPlantSpecies.preference.viableNutrition) * careAffinityMultiplier(for: .fertilizer)
        }
    }

    private func careAffinityMultiplier(for action: CareAction) -> Double {
        switch (selectedPlantSpecies.preference.careAffinity, action) {
        case (.water, .water), (.sunlight, .sunlight), (.fertilizer, .fertilizer):
            return 1.10
        default:
            return 1.0
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

        if selectedPlantSpecies.preference.preferredWeather.contains(flower.selectedWeather) {
            multiplier *= 1.16
        }

        if selectedPlantSpecies.preference.weakWeather.contains(flower.selectedWeather) {
            multiplier *= 0.78
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

    private func recordBloomIfNeeded(now: Date = Date()) {
        guard flower.bloomRecordedAt == nil else {
            return
        }

        let plant = selectedPlantSpecies
        let plantedAt = flower.plantedAt ?? flower.lastOpenedAt
        let daysToBloom = max(1, Calendar.current.dateComponents([.day], from: plantedAt, to: now).day ?? 1)
        let record = PlantBloomRecord(
            id: "\(plant.id)-\(Int(now.timeIntervalSince1970))",
            plantID: plant.id,
            plantName: plant.name,
            bloomImageName: plant.normalStageImageNames.last ?? plant.seedImageName,
            bloomedAt: now,
            daysToBloom: daysToBloom,
            careRank: bloomCareRank(daysToBloom: daysToBloom)
        )

        bloomRecords.insert(record, at: 0)
        encyclopediaStorageService.saveRecords(bloomRecords)
        flower.bloomRecordedAt = now
        isBloomBonusRewardPresented = flower.bloomBonusResolvedAt == nil
    }

    private func bloomCareRank(daysToBloom: Int) -> BloomCareRank {
        let conditionScore = (
            rangeScore(flower.water, ideal: selectedPlantSpecies.preference.idealWater, viable: selectedPlantSpecies.preference.viableWater) * 0.30 +
            rangeScore(flower.sunlight, ideal: selectedPlantSpecies.preference.idealSunlight, viable: selectedPlantSpecies.preference.viableSunlight) * 0.30 +
            rangeScore(flower.nutrition, ideal: selectedPlantSpecies.preference.idealNutrition, viable: selectedPlantSpecies.preference.viableNutrition) * 0.25 +
            rangeScore(flower.mood, ideal: selectedPlantSpecies.preference.idealMood, viable: selectedPlantSpecies.preference.viableMood) * 0.15
        )
        let stressPenalty = min(stressPercent / 100, 0.45)
        let riskPenalty = min(deathRiskPercent / 100, 0.35)
        let dayScore: Double

        switch daysToBloom {
        case ...24:
            dayScore = 1.0
        case 25...34:
            dayScore = 0.85
        case 35...49:
            dayScore = 0.68
        default:
            dayScore = 0.52
        }

        let score = conditionScore * 0.62 + dayScore * 0.38 - stressPenalty - riskPenalty

        switch score {
        case 0.82...:
            return .s
        case 0.66..<0.82:
            return .a
        case 0.48..<0.66:
            return .b
        default:
            return .c
        }
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

    private func applyWaterChange(_ amount: Double) {
        let effect = selectedVaseStyle.effect
        let adjustedAmount = amount >= 0 ? amount * effect.waterRetention : amount / effect.waterRetention
        flower.water = clamped(flower.water + adjustedAmount)
    }

    private func applySunlightChange(_ amount: Double) {
        let modifier = selectedVaseStyle.effect.sunlightModifier
        let adjustedAmount = amount >= 0 ? amount * modifier : amount / modifier
        flower.sunlight = clamped(flower.sunlight + adjustedAmount)
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

    private var currentPestDamage: Double {
        clamped(flower.pestDamage ?? 0)
    }

    var isPestRiskWeather: Bool {
        let temperature = currentTemperature ?? flower.lastTemperature ?? 23
        let weatherAllowsPests = flower.selectedWeather == .sunny || flower.selectedWeather == .cloudy
        return isCurrentWeatherDaytime && weatherAllowsPests && temperature >= 25
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

    private var currentOpenedDayCount: Int {
        max(flower.openedDayCount ?? 1, 1)
    }

    private func recordAppOpenedToday(now: Date = Date()) {
        grantDailyGachaTicketIfNeeded(now: now)

        if let lastOpenedDayCountedAt = flower.lastOpenedDayCountedAt,
           isDateInToday(lastOpenedDayCountedAt) {
            return
        }

        flower.openedDayCount = currentOpenedDayCount + 1
        flower.lastOpenedDayCountedAt = now
        storageService.saveFlower(flower)
    }

    private func grantDailyGachaTicketIfNeeded(now: Date = Date()) {
        if let lastGrantedAt = UserDefaults.standard.object(forKey: lastGachaTicketGrantedAtKey) as? Date,
           isDateInToday(lastGrantedAt) {
            return
        }

        gachaTicketCount += 1
        UserDefaults.standard.set(gachaTicketCount, forKey: gachaTicketCountKey)
        UserDefaults.standard.set(now, forKey: lastGachaTicketGrantedAtKey)
        isDailyGachaTicketRewardPresented = true
    }

    private var hasPoorCondition: Bool {
        conditionStressScore >= 1.0
    }

    private var hasGoodRecoveryCondition: Bool {
        waterIdealRange.contains(flower.water) &&
        sunlightIdealRange.contains(flower.sunlight) &&
        nutritionIdealRange.contains(flower.nutrition) &&
        selectedPlantSpecies.preference.viableMood.contains(flower.mood)
    }

    private var conditionStressScore: Double {
        var score: Double = 0
        let preference = selectedPlantSpecies.preference

        if flower.water >= preference.viableWater.upperBound + 2 {
            // 水が多すぎる状態が続くと根腐れリスクが高くなります。
            score += 2.2
        } else if flower.water >= preference.idealWater.upperBound + 12 {
            score += 1.45
        } else if flower.water >= preference.idealWater.upperBound + 6 {
            score += 0.8
        }

        if flower.water <= preference.viableWater.lowerBound - 18 {
            score += 2.2
        } else if flower.water <= preference.viableWater.lowerBound - 8 {
            score += 1.4
        } else if flower.water < preference.viableWater.lowerBound {
            score += 0.7
        }

        if flower.sunlight <= preference.viableSunlight.lowerBound - 18 {
            score += 1.7
        } else if flower.sunlight <= preference.viableSunlight.lowerBound - 8 {
            score += 1.1
        } else if flower.sunlight < preference.viableSunlight.lowerBound {
            score += 0.45
        }

        if flower.sunlight >= preference.viableSunlight.upperBound + 2 {
            score += 0.35
        }

        if flower.nutrition >= preference.viableNutrition.upperBound + 2 {
            // 肥料が多すぎる状態が続くと肥料焼けで弱りやすくなります。
            score += 2.0
        } else if flower.nutrition >= preference.idealNutrition.upperBound + 12 {
            score += 1.35
        } else if flower.nutrition >= preference.idealNutrition.upperBound + 6 {
            score += 0.75
        }

        if flower.nutrition <= preference.viableNutrition.lowerBound - 18 {
            score += 1.9
        } else if flower.nutrition <= preference.viableNutrition.lowerBound - 8 {
            score += 1.2
        } else if flower.nutrition < preference.viableNutrition.lowerBound {
            score += 0.5
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

        if preference.weakWeather.contains(flower.selectedWeather) {
            score += 0.35
        }

        switch pestDamagePercent {
        case 70...:
            score += 1.2
        case 50..<70:
            score += 0.65
        case 30..<50:
            score += 0.25
        default:
            break
        }

        return score / selectedVaseStyle.effect.stressResistance
    }

    private func updatePestDamage(hours: Double, daytimeHours: Double) {
        guard !isDead else {
            return
        }

        let temperature = currentTemperature ?? flower.lastTemperature ?? 23
        let isWarmEnough = temperature >= 25
        let weatherAllowsPests = flower.selectedWeather == .sunny || flower.selectedWeather == .cloudy

        if isWarmEnough, weatherAllowsPests, daytimeHours > 0 {
            let temperaturePressure = min(max((temperature - 25) / 10, 0), 1)
            let weatherPressure = flower.selectedWeather == .sunny ? 1.0 : 0.72
            let dryPressure = flower.water < 35 ? 0.18 : 0
            let overfedPressure = flower.nutrition > selectedPlantSpecies.preference.idealNutrition.upperBound ? 0.14 : 0
            let hourlyIncrease = (0.42 + temperaturePressure * 0.48 + dryPressure + overfedPressure) * weatherPressure
            flower.pestDamage = clamped(currentPestDamage + daytimeHours * hourlyIncrease / selectedVaseStyle.effect.stressResistance)
            return
        }

        let recoveryRate: Double
        switch flower.selectedWeather {
        case .rainy, .stormy:
            recoveryRate = 0.95
        case .windy:
            recoveryRate = 0.72
        default:
            recoveryRate = 0.28
        }

        reducePestDamage(by: hours * recoveryRate)
    }

    private func reducePestDamage(by amount: Double) {
        flower.pestDamage = max(0, currentPestDamage - amount)
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
