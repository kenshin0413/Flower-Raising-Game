//
//  ContentView.swift
//  Flower Raising Game
//
//  Created by miyamotokenshin on R 8/05/13.
//

import StoreKit
import SwiftUI
import UserNotifications
import WidgetKit

private enum RewardedCareAction {
    case water
    case sunlight
    case fertilizer

    var alertMessage: String {
        switch self {
        case .water:
            return "広告を見ると、今日もう一度だけ水やりできます。"
        case .sunlight:
            return "ライトは広告を見ると、今日一度だけ使えます。"
        case .fertilizer:
            return "広告を見ると、今日もう一度だけ肥料をあげられます。"
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = FlowerGardenViewModel()
    @StateObject private var backgroundMusicService = BackgroundMusicService()
    @StateObject private var appUpdateService = AppUpdateService()
    @StateObject private var rewardedAdService = RewardedAdService()
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var wateringEffectTrigger = 0
    @State private var lightEffectTrigger = 0
    @State private var fertilizerEffectTrigger = 0
    @State private var plantTapEffectTrigger = 0
    @State private var plantTapMessage: String?
    @State private var plantTapBonusText: String?
    @State private var plantTapMessageTask: Task<Void, Never>?
    @State private var reviewPromptPolicy = AppReviewPromptPolicy()
    @State private var isSettingsPresented = false
    @State private var isGachaPresented = false
    @State private var isPlantSelectionPresented = false
    @State private var isSleepyHours = ContentView.isSleepyHoursNow()
    @State private var pendingRewardedCareAction: RewardedCareAction?
    @State private var isRewardedAdConfirmationPresented = false
    @State private var isBloomBonusCelebrationPresented = false
    @State private var bloomBonusCelebrationID = 0
    @State private var isWidgetGuidePresented = false
    @AppStorage("widget_promotion_seen_v1") private var hasSeenWidgetPromotion = false

    var body: some View {
        ZStack {
            AnimatedWeatherBackgroundView(
                weather: viewModel.flower.selectedWeather,
                isDaytime: viewModel.isCurrentWeatherDaytime,
                windSpeed: viewModel.currentWindSpeed ?? viewModel.flower.lastWindSpeed,
                precipitation: viewModel.currentPrecipitation ?? viewModel.flower.lastPrecipitation
            )

            GeometryReader { geometry in
                let isCompact = geometry.size.height < 760
                let horizontalPadding: CGFloat = 20
                let verticalSpacing: CGFloat = isCompact ? 2 : 7
                let verticalPadding: CGFloat = isCompact ? 10 : 22
                let headerHeight: CGFloat = isCompact ? 118 : 108
                let growthCardHeight: CGFloat = 46
                let adviceCardHeight: CGFloat = 34
                let statCardHeight: CGFloat = 54
                let actionCardHeight: CGFloat = isCompact ? 68 : 82
                let spacingHeight = verticalSpacing * 5
                let reservedHeight = verticalPadding + headerHeight + growthCardHeight + adviceCardHeight + statCardHeight + actionCardHeight + spacingHeight
                let availablePlantHeight = geometry.size.height - reservedHeight
                let minimumPlantHeight: CGFloat = isCompact ? 172 : 285
                let maximumPlantHeight: CGFloat = isCompact ? 306 : 590
                let plantHeight = min(max(availablePlantHeight, minimumPlantHeight), maximumPlantHeight)
                let uiOpacity = isSleepyHours ? 0.62 : 1

                VStack(spacing: verticalSpacing) {
                    GardenHeaderView(
                        weatherEmoji: viewModel.weatherDisplayEmoji,
                        weatherName: viewModel.weatherDisplayName,
                        temperatureText: viewModel.temperatureText,
                        humidityText: viewModel.humidityText,
                        windSpeedText: viewModel.windSpeedText,
                        careStreakText: viewModel.careStreakText,
                        onGachaTap: {
                            isGachaPresented = true
                        },
                        onSettingsTap: {
                            isSettingsPresented = true
                        }
                    )
                    .opacity(uiOpacity)

                    ZStack {
                        FlowerHeroView(
                            flower: viewModel.flower,
                            plantImageName: displayedPlantImageName,
                            vaseStyle: viewModel.selectedVaseStyle,
                            growthPercentText: displayedGrowthPercentText,
                            imageHeight: plantHeight,
                            windSpeed: viewModel.currentWindSpeed ?? viewModel.flower.lastWindSpeed,
                            onTap: reactToPlantTap
                        )

                        PlantTapReactionView(
                            trigger: plantTapEffectTrigger,
                            imageHeight: plantHeight,
                            message: plantTapMessage
                        )
                        .allowsHitTesting(false)

                        WateringEffectView(
                            trigger: wateringEffectTrigger,
                            imageHeight: plantHeight
                        )

                        LightEffectView(
                            trigger: lightEffectTrigger,
                            imageHeight: plantHeight
                        )

                        FertilizerEffectView(
                            trigger: fertilizerEffectTrigger,
                            imageHeight: plantHeight
                        )

                        PestInfestationEffectView(
                            severity: viewModel.pestDamagePercent,
                            isRiskActive: viewModel.isPestRiskWeather,
                            imageHeight: plantHeight
                        )

                    }

                    GrowthStageCardView(
                        stageName: displayedStageName,
                        stageProgress: displayedGrowthProgressPercent,
                        stageProgressText: displayedGrowthPercentText
                    )
                    .opacity(uiOpacity)

                    CareAdviceView(
                        text: viewModel.careAdviceText,
                        systemImage: viewModel.careAdviceSystemImage,
                        color: viewModel.careAdviceColor
                    )
                    .opacity(uiOpacity)

                    if let plantTapBonusText {
                        Text(plantTapBonusText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.cyan.opacity(0.92))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .opacity(uiOpacity)
                    }

                    HStack(spacing: 0) {
                        StatChipView(
                            title: "水分",
                            value: viewModel.flower.water,
                            color: .cyan,
                            systemImage: "drop.fill",
                            statusText: viewModel.waterStatusText,
                            statusColor: viewModel.waterStatusColor,
                            idealRange: viewModel.waterIdealRange
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "日光",
                            value: viewModel.flower.sunlight,
                            color: .orange,
                            systemImage: "sun.max.fill",
                            statusText: viewModel.sunlightStatusText,
                            statusColor: viewModel.sunlightStatusColor,
                            idealRange: viewModel.sunlightIdealRange
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "栄養",
                            value: viewModel.flower.nutrition,
                            color: .green,
                            systemImage: "leaf.fill",
                            statusText: viewModel.nutritionStatusText,
                            statusColor: viewModel.nutritionStatusColor,
                            idealRange: viewModel.nutritionIdealRange
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "虫害",
                            value: viewModel.pestDamagePercent,
                            color: .red,
                            systemImage: "ladybug.fill",
                            statusText: viewModel.pestDamageStatusText,
                            statusColor: viewModel.pestDamageStatusColor,
                            idealRange: viewModel.pestDamageIdealRange
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "枯れリスク",
                            value: viewModel.deathRiskPercent,
                            color: .purple,
                            systemImage: "flame.fill",
                            statusText: viewModel.deathRiskStatusText,
                            statusColor: viewModel.deathRiskStatusColor,
                            idealRange: viewModel.deathRiskIdealRange
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)
                    .opacity(uiOpacity)

                    ActionButtonsView(
                        isDead: viewModel.isDead,
                        isFullyBloomed: viewModel.isFullyBloomed,
                        canWater: viewModel.canTapWaterAction,
                        canGiveSunlight: viewModel.canTapSunlightAction,
                        canFeed: viewModel.canTapFeedAction,
                        waterSubtitle: viewModel.waterActionSubtitle,
                        sunlightSubtitle: viewModel.sunlightActionSubtitle,
                        feedSubtitle: viewModel.feedActionSubtitle,
                        isCompact: isCompact,
                        onReplant: viewModel.resetFlower,
                        onChooseSeed: {
                            isPlantSelectionPresented = true
                        },
                        onWater: waterFlowerWithEffect,
                        onSunlight: giveLightWithEffect,
                        onFeed: feedFlowerWithEffect
                    )
                    .opacity(uiOpacity)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isCompact ? 8 : 12)
                .padding(.bottom, isCompact ? 4 : 10)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }

            if viewModel.isDailyGachaTicketRewardPresented {
                DailyTicketRewardOverlay(
                    ticketCountText: viewModel.gachaTicketText,
                    onDismiss: viewModel.dismissDailyGachaTicketReward
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(10)
            }

            if viewModel.isBloomBonusRewardPresented {
                BloomBonusRewardOfferOverlay(
                    plantName: viewModel.selectedPlantSpecies.name,
                    flowerImageName: viewModel.plantImageName,
                    ticketCountText: viewModel.gachaTicketText,
                    onWatchAd: showBloomBonusRewardAd,
                    onSkip: viewModel.dismissBloomBonusReward
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(12)
            }

            if isBloomBonusCelebrationPresented {
                BloomBonusRewardCelebrationOverlay(
                    id: bloomBonusCelebrationID,
                    ticketCountText: viewModel.gachaTicketText,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isBloomBonusCelebrationPresented = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(13)
            }

            if rewardedAdService.isLoading {
                RewardedAdLoadingOverlay()
                    .zIndex(20)
            }
        }
        .onAppear {
            isSleepyHours = Self.isSleepyHoursNow()
            backgroundMusicService.startIfEnabled()
        }
        .alert("広告を見ますか？", isPresented: $isRewardedAdConfirmationPresented) {
            Button("キャンセル", role: .cancel) {
                pendingRewardedCareAction = nil
            }

            Button("見る") {
                guard let action = pendingRewardedCareAction else {
                    return
                }

                viewModel.markRewardedAdPromptSeen()
                showRewardedAd(for: action)
            }
        } message: {
            Text(pendingRewardedCareAction?.alertMessage ?? "広告を見ると追加の報酬を受け取れます。")
        }
        .alert("アップデートがあります", isPresented: updateAlertBinding) {
            Button("あとで", role: .cancel) {
                appUpdateService.dismissCurrentUpdate()
            }

            Button("アップデート") {
                guard let storeURL = appUpdateService.availableUpdate?.storeURL else {
                    appUpdateService.dismissCurrentUpdate()
                    return
                }

                openURL(storeURL)
                appUpdateService.dismissCurrentUpdate()
            }
        } message: {
            Text(updateAlertMessage)
        }
        .sheet(isPresented: $isSettingsPresented) {
            GameSettingsView(
                backgroundMusicService: backgroundMusicService,
                flowerGardenViewModel: viewModel
            )
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isGachaPresented) {
            GachaView(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isPlantSelectionPresented) {
            NavigationStack {
                PlantAndVaseSelectionView(viewModel: viewModel)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isWidgetGuidePresented, onDismiss: {
            hasSeenWidgetPromotion = true
        }) {
            WidgetSetupGuideView {
                hasSeenWidgetPromotion = true
                isWidgetGuidePresented = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                backgroundMusicService.startIfEnabled()
            } else {
                backgroundMusicService.pause()
            }

            guard newPhase == .active else {
                return
            }

            viewModel.applyElapsedTimeIfNeeded()
            WidgetCenter.shared.reloadAllTimelines()

            Task {
                await viewModel.refreshRealWeather()
                await appUpdateService.checkForUpdateIfNeeded()
            }
        }
        .task {
            await appUpdateService.checkForUpdateIfNeeded(force: true)
        }
        .task {
            await presentWidgetPromotionIfNeeded()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 600_000_000_000)
                guard !Task.isCancelled else {
                    return
                }
                viewModel.applyElapsedTimeIfNeeded()
            }
        }
        .task {
            while !Task.isCancelled {
                isSleepyHours = Self.isSleepyHoursNow()
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
        }
    }

    private var displayedPlantImageName: String? {
        viewModel.plantImageName
    }

    private func presentWidgetPromotionIfNeeded() async {
        guard !hasSeenWidgetPromotion else {
            return
        }

        let isInstalled = await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                let installed = (try? result.get())?.contains { $0.kind == "FlowerCareWidgetV2" } ?? false
                continuation.resume(returning: installed)
            }
        }

        if isInstalled {
            hasSeenWidgetPromotion = true
            return
        }

        // 初回の許可ダイアログや起動画面と重ならないよう、少し待ってから案内します。
        try? await Task.sleep(for: .seconds(2.5))

        for _ in 0..<30 {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .notDetermined else {
                break
            }
            try? await Task.sleep(for: .seconds(1))
        }

        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        guard !Task.isCancelled, !hasSeenWidgetPromotion else {
            return
        }
        guard notificationSettings.authorizationStatus != .notDetermined else {
            return
        }
        isWidgetGuidePresented = true
    }

    private var displayedGrowthPercentText: String {
        viewModel.growthPercentText
    }

    private var displayedGrowthProgressPercent: Double {
        viewModel.growthProgressPercent
    }

    private var displayedStageName: String {
        viewModel.stageName
    }

    private var updateAlertBinding: Binding<Bool> {
        Binding(
            get: {
                appUpdateService.availableUpdate != nil
            },
            set: { isPresented in
                if !isPresented {
                    appUpdateService.dismissCurrentUpdate()
                }
            }
        )
    }

    private var updateAlertMessage: String {
        guard let update = appUpdateService.availableUpdate else {
            return "新しいバージョンが利用できます。"
        }

        return "現在のバージョンは\(update.currentVersion)です。新しいバージョン\(update.latestVersion)にアップデートできます。"
    }

    private func reactToPlantTap() {
        viewModel.applyPlantTapBonus()
        plantTapEffectTrigger += 1
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            plantTapMessage = plantTapReactionMessage()
            plantTapBonusText = "水分 +0.5%　日光 +0.5%　肥料 +0.5%"
        }
        plantTapMessageTask?.cancel()
        plantTapMessageTask = Task {
            try? await Task.sleep(nanoseconds: 2_050_000_000)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) {
                    plantTapMessage = nil
                    plantTapBonusText = nil
                }
            }
        }
    }

    private func plantTapReactionMessage() -> String {
        if viewModel.isDead {
            let messages = [
                "また会える日を待ってるね",
                "次の種に、気持ちをつないでね",
                "ここまで育ててくれてありがとう"
            ]
            return messages.randomElement() ?? messages[0]
        }

        if viewModel.isFullyBloomed {
            let messages = [
                "見て、きれいに咲けたよ",
                "ここまで一緒にいてくれてありがとう",
                "今日の光、花びらまで届いてるよ",
                "咲いた姿、覚えていてね"
            ]
            return messages.randomElement() ?? messages[0]
        }

        if viewModel.isWilted {
            let messages = [
                "少しだけ休ませてね",
                "そばにいてくれるだけで落ち着くよ",
                "明日はもう少し元気になりたいな",
                "ゆっくり整えていこうね"
            ]
            return messages.randomElement() ?? messages[0]
        }

        if viewModel.pestDamagePercent >= 45 {
            let messages = [
                "葉っぱが少しかゆいみたい",
                "小さな虫が増えてきたよ",
                "今日は様子をよく見てね",
                "虫害が落ち着くと元気になれるよ"
            ]
            return messages.randomElement() ?? messages[0]
        }

        if viewModel.stressPercent >= 35 {
            let messages = [
                "今日は静かに見守ってね",
                "ちょっと深呼吸したい気分だよ",
                "急がなくて大丈夫だよ",
                "少しずつ元気を戻すね"
            ]
            return messages.randomElement() ?? messages[0]
        }

        let messages = [
            "今日も会いに来てくれたね",
            "あなたの気配、ちゃんと分かるよ",
            "少し背伸びしてみたよ",
            "この鉢、けっこう気に入ってるよ",
            "空の色が変わるの、好きなんだ",
            "水の音を聞くと落ち着くよ",
            "光があたると、からだが目を覚ますよ",
            "根っこまでぽかぽかしてるよ",
            "明日はどんな天気かな",
            "ゆっくりでも、ちゃんと育ってるよ",
            "近くで見てくれてうれしいよ",
            "葉っぱが少し揺れたの、気づいた？",
            "この場所、だんだん好きになってきたよ",
            "今日の空気、根っこまで届いてるよ",
            "小さな変化も見つけてくれる？",
            "あなたの声がした気がしたよ",
            "次の葉っぱを準備してるところだよ",
            "もう少しだけ近くで見ていてね",
            "風の音を聞きながら育ってるよ",
            "今日のわたし、少し元気そうでしょ"
        ]
        return messages.randomElement() ?? messages[0]
    }

    private func waterFlowerWithEffect() {
        if viewModel.canWaterToday {
            wateringEffectTrigger += 1
            viewModel.waterFlower()
            requestReviewIfAppropriate()
            return
        }

        requestRewardedCare(.water)
    }

    private func giveLightWithEffect() {
        guard viewModel.canWatchAdForSunlightToday else {
            return
        }

        requestRewardedCare(.sunlight)
    }

    private func feedFlowerWithEffect() {
        if viewModel.canFeedToday {
            fertilizerEffectTrigger += 1
            viewModel.feedFlower()
            requestReviewIfAppropriate()
            return
        }

        requestRewardedCare(.fertilizer)
    }

    private func requestRewardedCare(_ action: RewardedCareAction) {
        guard !rewardedAdService.isLoading else {
            return
        }

        pendingRewardedCareAction = action

        if viewModel.shouldShowRewardedAdPrompt {
            isRewardedAdConfirmationPresented = true
            return
        }

        showRewardedAd(for: action)
    }

    private func showRewardedAd(for action: RewardedCareAction) {
        Task {
            let didEarnReward = await rewardedAdService.showRewardedAd()
            guard didEarnReward else {
                pendingRewardedCareAction = nil
                return
            }

            applyRewardedCare(action)
            pendingRewardedCareAction = nil
        }
    }

    private func applyRewardedCare(_ action: RewardedCareAction) {
        switch action {
        case .water:
            wateringEffectTrigger += 1
            viewModel.applyRewardedWaterCare()
        case .sunlight:
            lightEffectTrigger += 1
            viewModel.applyRewardedSunlightCare()
        case .fertilizer:
            fertilizerEffectTrigger += 1
            viewModel.applyRewardedFertilizerCare()
        }

        requestReviewIfAppropriate()
    }

    private func showBloomBonusRewardAd() {
        guard !rewardedAdService.isLoading else {
            return
        }

        Task {
            let didEarnReward = await rewardedAdService.showRewardedAd()
            guard didEarnReward,
                  viewModel.grantBloomBonusReward() else {
                return
            }

            bloomBonusCelebrationID += 1
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                isBloomBonusCelebrationPresented = true
            }
        }
    }

    private func requestReviewIfAppropriate() {
        guard reviewPromptPolicy.shouldRequestReviewAfterCareAction() else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            requestReview()
        }
    }

    private static func isSleepyHoursNow(date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= 22 || hour < 6
    }
}

private struct RewardedAdLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(.green)

                Text("広告を読み込み中")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.84))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .brown.opacity(0.16), radius: 18, y: 10)
        }
    }
}

private struct BloomBonusRewardOfferOverlay: View {
    let plantName: String
    let flowerImageName: String?
    let ticketCountText: String
    let onWatchAd: () -> Void
    let onSkip: () -> Void

    @State private var isPresented = false
    @State private var haloPulse = false
    @State private var flowerLift = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            ForEach(0..<26, id: \.self) { index in
                BloomOfferPetal(index: index, isActive: isPresented)
            }

            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.pink.opacity(haloPulse ? 0.34 : 0.18),
                                    Color.yellow.opacity(haloPulse ? 0.24 : 0.12),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 6,
                                endRadius: 130
                            )
                        )
                        .frame(width: 232, height: 232)
                        .scaleEffect(haloPulse ? 1.08 : 0.94)

                    if let flowerImageName {
                        Image(flowerImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 142, height: 142)
                            .padding(10)
                            .background(.white.opacity(0.64))
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: .pink.opacity(0.18), radius: 22, y: 10)
                            .offset(y: flowerLift ? -8 : 12)
                    } else {
                        Image(systemName: "camera.macro")
                            .font(.system(size: 70, weight: .black))
                            .foregroundStyle(.pink.opacity(0.72))
                            .offset(y: flowerLift ? -8 : 12)
                    }

                    Image(systemName: "ticket.fill")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .green.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(12)
                        .background(.white.opacity(0.90))
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .offset(x: 78, y: -62)
                        .rotationEffect(.degrees(flowerLift ? 8 : -5))
                }
                .frame(height: 170)

                VStack(spacing: 7) {
                    Text("開花記念ボーナス")
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(.brown.opacity(0.90))

                    Text("\(plantName)が咲きました")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.pink.opacity(0.72))

                    Text("広告を見るとガチャチケットを5枚受け取れます")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.brown.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)

                    Text("見送ると報酬はありません・所持 \(ticketCountText)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.brown.opacity(0.44))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 9) {
                    Button(action: onWatchAd) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 17, weight: .black))

                            Text("広告を見て +5枚")
                                .font(.system(size: 16, weight: .black))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [.green.opacity(0.88), .mint.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .green.opacity(0.18), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)

                    Button(action: onSkip) {
                        Text("今回は受け取らない")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.56))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(.white.opacity(0.56))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: 318)
            .background(.white.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            )
            .shadow(color: .brown.opacity(0.18), radius: 30, y: 16)
            .scaleEffect(isPresented ? 1 : 0.86)
            .opacity(isPresented ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                isPresented = true
                flowerLift = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                haloPulse = true
            }
        }
    }
}

private struct BloomBonusRewardCelebrationOverlay: View {
    let id: Int
    let ticketCountText: String
    let onDismiss: () -> Void

    @State private var isPresented = false
    @State private var ticketBurst = false
    @State private var haloPulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)
                .ignoresSafeArea()

            ForEach(0..<42, id: \.self) { index in
                BloomBonusBurstParticle(index: index, isActive: isPresented)
            }

            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(haloPulse ? 0.66 : 0.36),
                                    Color.green.opacity(haloPulse ? 0.30 : 0.14),
                                    Color.pink.opacity(haloPulse ? 0.18 : 0.08),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 150
                            )
                        )
                        .frame(width: 264, height: 264)
                        .scaleEffect(haloPulse ? 1.08 : 0.92)

                    HStack(spacing: -16) {
                        ForEach(0..<5, id: \.self) { index in
                            BloomBonusTicketCard(index: index, isActive: ticketBurst)
                        }
                    }
                }
                .frame(height: 182)

                VStack(spacing: 7) {
                    Text("チケット5枚獲得")
                        .font(.system(size: 27, weight: .black))
                        .foregroundStyle(.brown.opacity(0.90))

                    Text("+5枚")
                        .font(.system(size: 25, weight: .black).monospacedDigit())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .green.opacity(0.94)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("所持 \(ticketCountText)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.brown.opacity(0.58))
                }

                Text("開花まで育てた記念報酬です")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.50))

                Button {
                    dismiss()
                } label: {
                    Text("受け取る")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.green.opacity(0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: 310)
            .background(.white.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            )
            .shadow(color: .brown.opacity(0.18), radius: 30, y: 16)
            .scaleEffect(isPresented ? 1 : 0.84)
            .opacity(isPresented ? 1 : 0)
        }
        .onAppear {
            isPresented = false
            ticketBurst = false
            haloPulse = false

            withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                isPresented = true
            }
            withAnimation(.interpolatingSpring(stiffness: 92, damping: 9).delay(0.08)) {
                ticketBurst = true
            }
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                haloPulse = true
            }
        }
        .id(id)
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.22)) {
            isPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}

private struct BloomOfferPetal: View {
    let index: Int
    let isActive: Bool

    private var angle: Double {
        Double(index) / 26 * .pi * 2
    }

    var body: some View {
        Capsule()
            .fill(index.isMultiple(of: 2) ? Color.pink.opacity(0.62) : Color.yellow.opacity(0.56))
            .frame(width: CGFloat(5 + index % 4), height: CGFloat(11 + index % 6))
            .rotationEffect(.degrees(Double(index * 31)))
            .offset(
                x: cos(angle) * (isActive ? Double(118 + index % 44) : 24),
                y: sin(angle) * (isActive ? Double(104 + index % 38) : 18)
            )
            .opacity(isActive ? 1 : 0)
            .animation(.spring(response: 0.72, dampingFraction: 0.78).delay(Double(index) * 0.02), value: isActive)
    }
}

private struct BloomBonusTicketCard: View {
    let index: Int
    let isActive: Bool

    private var rotation: Double {
        [-18, -8, 0, 8, 18][index]
    }

    private var yOffset: CGFloat {
        [18, 4, -10, 5, 20][index]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white,
                            Color.yellow.opacity(0.36),
                            Color.green.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: index == 2 ? 78 : 64, height: index == 2 ? 96 : 82)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.84), lineWidth: 1.3)
                )

            VStack(spacing: 7) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: index == 2 ? 30 : 23, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .green.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("+1")
                    .font(.system(size: index == 2 ? 15 : 12, weight: .black).monospacedDigit())
                    .foregroundStyle(.brown.opacity(0.74))
            }
        }
        .rotationEffect(.degrees(isActive ? rotation : 0))
        .offset(y: isActive ? yOffset : 42)
        .scaleEffect(isActive ? 1 : 0.62)
        .opacity(isActive ? 1 : 0)
        .shadow(color: .green.opacity(index == 2 ? 0.22 : 0.12), radius: index == 2 ? 18 : 10, y: 7)
        .animation(.interpolatingSpring(stiffness: 94, damping: 9).delay(Double(index) * 0.045), value: isActive)
    }
}

private struct BloomBonusBurstParticle: View {
    let index: Int
    let isActive: Bool

    private var angle: Double {
        Double(index) / 42 * .pi * 2
    }

    var body: some View {
        Group {
            if index.isMultiple(of: 6) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: CGFloat(8 + index % 6), weight: .black))
                    .foregroundStyle(Color.yellow.opacity(0.88))
            } else if index.isMultiple(of: 3) {
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(8 + index % 7), weight: .black))
                    .foregroundStyle(.white.opacity(0.88))
            } else {
                Capsule()
                    .fill((index.isMultiple(of: 2) ? Color.green : Color.pink).opacity(0.66))
                    .frame(width: CGFloat(5 + index % 4), height: CGFloat(10 + index % 5))
                    .rotationEffect(.degrees(Double(index * 29)))
            }
        }
        .offset(
            x: cos(angle) * (isActive ? Double(130 + index % 64) : 28),
            y: sin(angle) * (isActive ? Double(118 + index % 48) : 20)
        )
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.75, dampingFraction: 0.78).delay(Double(index) * 0.015), value: isActive)
    }
}

private struct PlantTapReactionView: View {
    let trigger: Int
    let imageHeight: CGFloat
    let message: String?

    @State private var isActive = false

    var body: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { index in
                PlantTapParticle(
                    index: index,
                    isActive: isActive,
                    imageHeight: imageHeight
                )
            }

            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(maxWidth: min(imageHeight * 0.78, 286))
                    .background(.white.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(.white.opacity(0.70), lineWidth: 1)
                    )
                    .shadow(color: .brown.opacity(0.12), radius: 10, y: 5)
                    .offset(y: -imageHeight * 0.42)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else {
                return
            }

            isActive = false

            withAnimation(.easeOut(duration: 0.62)) {
                isActive = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
                withAnimation(.easeIn(duration: 0.16)) {
                    isActive = false
                }
            }
        }
    }
}

private struct PestInfestationEffectView: View {
    let severity: Double
    let isRiskActive: Bool
    let imageHeight: CGFloat

    private var isVisible: Bool {
        isRiskActive
    }

    private var bugCount: Int {
        switch severity {
        case 70...:
            return 9
        case 45..<70:
            return 6
        default:
            return 3
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(0..<bugCount, id: \.self) { index in
                    PestBugParticle(
                        index: index,
                        time: time,
                        imageHeight: imageHeight,
                        severity: severity
                    )
                }
            }
            .opacity(isVisible ? min(0.28 + severity / 120, 0.92) : 0)
            .animation(.easeInOut(duration: 0.25), value: isVisible)
        }
        .allowsHitTesting(false)
    }
}

private struct PestBugParticle: View {
    let index: Int
    let time: TimeInterval
    let imageHeight: CGFloat
    let severity: Double

    private var baseX: CGFloat {
        let positions: [CGFloat] = [-0.19, -0.08, 0.08, 0.18, -0.24, 0.24, -0.12, 0.14, 0.02]
        return imageHeight * positions[index % positions.count]
    }

    private var baseY: CGFloat {
        let positions: [CGFloat] = [-0.04, -0.18, -0.12, -0.25, 0.04, -0.02, -0.31, -0.34, -0.22]
        return imageHeight * positions[index % positions.count]
    }

    var body: some View {
        let phase = time * (0.75 + Double(index % 4) * 0.11) + Double(index) * 0.8
        let driftX = CGFloat(sin(phase)) * imageHeight * 0.018
        let driftY = CGFloat(cos(phase * 0.8)) * imageHeight * 0.012

        Image(systemName: "ladybug.fill")
            .font(.system(size: CGFloat(8 + (index % 3) * 2), weight: .bold))
            .foregroundStyle(index.isMultiple(of: 2) ? .red.opacity(0.76) : .brown.opacity(0.70))
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            .rotationEffect(.degrees(sin(phase) * 16))
            .offset(x: baseX + driftX, y: baseY + driftY)
            .scaleEffect(0.82 + min(severity / 160, 0.45))
    }
}

private struct PlantTapParticle: View {
    let index: Int
    let isActive: Bool
    let imageHeight: CGFloat

    var body: some View {
        Capsule()
            .fill(color.opacity(isActive ? 0.82 : 0))
            .frame(width: particleSize.width, height: particleSize.height)
            .scaleEffect(isActive ? 1.0 : 0.45)
            .rotationEffect(.degrees(isActive ? finalRotation : startRotation))
            .offset(
                x: isActive ? finalX : startX,
                y: isActive ? finalY : startY
            )
            .animation(.easeOut(duration: 0.72).delay(Double(index) * 0.025), value: isActive)
    }

    private var color: Color {
        switch index % 3 {
        case 0:
            return Color(red: 0.98, green: 0.68, blue: 0.72)
        case 1:
            return Color(red: 0.98, green: 0.86, blue: 0.42)
        default:
            return Color(red: 0.48, green: 0.78, blue: 0.44)
        }
    }

    private var particleSize: CGSize {
        let base = max(8, imageHeight * 0.030)
        let width = base * (0.62 + CGFloat((index % 3)) * 0.08)
        return CGSize(width: width, height: base * 1.78)
    }

    private var startX: CGFloat {
        finalX * 0.42
    }

    private var startY: CGFloat {
        imageHeight * -0.17
    }

    private var finalX: CGFloat {
        imageHeight * CGFloat(path[index % path.count].x)
    }

    private var finalY: CGFloat {
        imageHeight * CGFloat(path[index % path.count].y)
    }

    private var startRotation: Double {
        finalRotation * 0.35
    }

    private var finalRotation: Double {
        [-28, -14, 8, 24, 38, -34, -8, 18, 32][index % 9]
    }

    private var path: [(x: Double, y: Double)] {
        [
            (-0.14, -0.31),
            (-0.09, -0.38),
            (-0.03, -0.34),
            (0.04, -0.40),
            (0.10, -0.33),
            (0.15, -0.37),
            (-0.17, -0.25),
            (0.00, -0.44),
            (0.17, -0.27)
        ]
    }
}

private struct DailyTicketRewardOverlay: View {
    let ticketCountText: String
    let onDismiss: () -> Void

    @State private var isPresented = false
    @State private var glowPulse = false
    @State private var ticketRise = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            ForEach(0..<22, id: \.self) { index in
                DailyTicketSparkle(index: index, isActive: isPresented)
            }

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(glowPulse ? 0.52 : 0.28),
                                    Color.green.opacity(glowPulse ? 0.22 : 0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 118
                            )
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(glowPulse ? 1.08 : 0.92)

                    Image(systemName: "ticket.fill")
                        .font(.system(size: 58, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.yellow,
                                    Color.green.opacity(0.92)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 112, height: 112)
                        .background(.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.86), lineWidth: 1.5)
                        )
                        .shadow(color: .yellow.opacity(0.28), radius: 22, y: 12)
                        .offset(y: ticketRise ? -8 : 12)
                        .rotationEffect(.degrees(ticketRise ? -5 : 3))
                }
                .frame(height: 150)

                VStack(spacing: 6) {
                    Text("チケットゲット")
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(.brown.opacity(0.88))

                    Text("+1枚")
                        .font(.system(size: 20, weight: .black).monospacedDigit())
                        .foregroundStyle(.green.opacity(0.92))

                    Text("所持 \(ticketCountText)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.brown.opacity(0.58))
                }

                Button {
                    dismiss()
                } label: {
                    Text("受け取る")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.green.opacity(0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 290)
            .background(.white.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: .brown.opacity(0.16), radius: 28, y: 16)
            .scaleEffect(isPresented ? 1 : 0.86)
            .opacity(isPresented ? 1 : 0)
        }
        .allowsHitTesting(true)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.74)) {
                isPresented = true
                ticketRise = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.22)) {
            isPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}

private struct DailyTicketSparkle: View {
    let index: Int
    let isActive: Bool

    var body: some View {
        Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "circle.fill")
            .font(.system(size: 5 + randomValue(salt: 13) * 9, weight: .bold))
            .foregroundStyle(sparkleColor.opacity(isActive ? 0.62 : 0))
            .offset(
                x: CGFloat(-145 + randomValue(salt: 3) * 290),
                y: CGFloat(-185 + randomValue(salt: 7) * 370)
            )
            .scaleEffect(isActive ? 1 : 0.2)
            .animation(
                .easeOut(duration: 0.7)
                .delay(Double(index) * 0.018),
                value: isActive
            )
    }

    private var sparkleColor: Color {
        switch index % 4 {
        case 0:
            return .yellow
        case 1:
            return .green
        case 2:
            return .mint
        default:
            return .white
        }
    }

    private func randomValue(salt: Int) -> Double {
        let raw = (index + 1) * 1103515245 + salt * 12345
        return Double(abs(raw % 1000)) / 1000.0
    }
}

private struct AppReviewPromptPolicy {
    private let firstCareActionDateKey = "reviewPrompt.firstCareActionDate"
    private let qualifyingCareActionCountKey = "reviewPrompt.qualifyingCareActionCount"
    private let nextPromptActionCountKey = "reviewPrompt.nextPromptActionCount"
    private let lastPromptDateKey = "reviewPrompt.lastPromptDate"
    private let promptHistoryKey = "reviewPrompt.promptHistory"

    private let minimumDaysSinceFirstCareAction: TimeInterval = 2 * 24 * 60 * 60
    private let minimumDaysBetweenPrompts: TimeInterval = 21 * 24 * 60 * 60
    private let initialPromptActionCount = 4
    private let promptActionInterval = 8
    private let maximumPromptsPerYear = 3

    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func shouldRequestReviewAfterCareAction(now: Date = Date()) -> Bool {
        let firstCareActionDate = storedFirstCareActionDate(now: now)
        let actionCount = incrementedCareActionCount()
        let nextPromptActionCount = storedNextPromptActionCount()

        guard actionCount >= nextPromptActionCount else {
            return false
        }

        guard now.timeIntervalSince(firstCareActionDate) >= minimumDaysSinceFirstCareAction else {
            return false
        }

        if let lastPromptDate = userDefaults.object(forKey: lastPromptDateKey) as? Date,
           now.timeIntervalSince(lastPromptDate) < minimumDaysBetweenPrompts {
            return false
        }

        let recentPromptHistory = promptHistory(since: oneYearAgo(from: now))
        guard recentPromptHistory.count < maximumPromptsPerYear else {
            return false
        }

        userDefaults.set(now, forKey: lastPromptDateKey)
        userDefaults.set(recentPromptHistory + [now], forKey: promptHistoryKey)
        userDefaults.set(actionCount + promptActionInterval, forKey: nextPromptActionCountKey)
        return true
    }

    private func storedFirstCareActionDate(now: Date) -> Date {
        if let date = userDefaults.object(forKey: firstCareActionDateKey) as? Date {
            return date
        }

        userDefaults.set(now, forKey: firstCareActionDateKey)
        return now
    }

    private func incrementedCareActionCount() -> Int {
        let actionCount = userDefaults.integer(forKey: qualifyingCareActionCountKey) + 1
        userDefaults.set(actionCount, forKey: qualifyingCareActionCountKey)
        return actionCount
    }

    private func storedNextPromptActionCount() -> Int {
        let actionCount = userDefaults.integer(forKey: nextPromptActionCountKey)
        return actionCount == 0 ? initialPromptActionCount : actionCount
    }

    private func promptHistory(since date: Date) -> [Date] {
        let history = userDefaults.array(forKey: promptHistoryKey) as? [Date] ?? []
        return history.filter { $0 >= date }
    }

    private func oneYearAgo(from date: Date) -> Date {
        calendar.date(byAdding: .year, value: -1, to: date) ?? date.addingTimeInterval(-365 * 24 * 60 * 60)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
