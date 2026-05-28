//
//  ContentView.swift
//  Flower Raising Game
//
//  Created by miyamotokenshin on R 8/05/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FlowerGardenViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var wateringEffectTrigger = 0
    @State private var lightEffectTrigger = 0
    @State private var fertilizerEffectTrigger = 0

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
                let headerHeight: CGFloat = isCompact ? 112 : 98
                let growthCardHeight: CGFloat = 46
                let adviceCardHeight: CGFloat = 34
                let statCardHeight: CGFloat = 54
                let actionCardHeight: CGFloat = isCompact ? 68 : 82
                let spacingHeight = verticalSpacing * 5
                let reservedHeight = verticalPadding + headerHeight + growthCardHeight + adviceCardHeight + statCardHeight + actionCardHeight + spacingHeight
                let availablePlantHeight = geometry.size.height - reservedHeight
                let minimumPlantHeight: CGFloat = isCompact ? 190 : 285
                let maximumPlantHeight: CGFloat = isCompact ? 306 : 590
                let plantHeight = min(max(availablePlantHeight, minimumPlantHeight), maximumPlantHeight)

                VStack(spacing: verticalSpacing) {
                    GardenHeaderView(
                        weatherEmoji: viewModel.weatherDisplayEmoji,
                        weatherName: viewModel.weatherDisplayName,
                        temperatureText: viewModel.temperatureText,
                        humidityText: viewModel.humidityText,
                        windSpeedText: viewModel.windSpeedText,
                        careStreakText: viewModel.careStreakText
                    )

                    ZStack {
                        FlowerHeroView(
                            flower: viewModel.flower,
                            plantImageName: viewModel.plantImageName,
                            growthPercentText: viewModel.growthPercentText,
                            imageHeight: plantHeight,
                            windSpeed: viewModel.currentWindSpeed ?? viewModel.flower.lastWindSpeed
                        )

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
                    }

                    GrowthStageCardView(
                        stageName: viewModel.stageName,
                        stageProgress: viewModel.growthProgressPercent,
                        stageProgressText: viewModel.growthPercentText
                    )

                    CareAdviceView(
                        text: viewModel.careAdviceText,
                        systemImage: viewModel.careAdviceSystemImage,
                        color: viewModel.careAdviceColor
                    )

                    HStack(spacing: 0) {
                        StatChipView(
                            title: "水分",
                            value: viewModel.flower.water,
                            color: .cyan,
                            systemImage: "drop.fill",
                            statusText: viewModel.waterStatusText,
                            statusColor: viewModel.waterStatusColor,
                            idealRange: 55...88
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "日光",
                            value: viewModel.flower.sunlight,
                            color: .orange,
                            systemImage: "sun.max.fill",
                            statusText: viewModel.sunlightStatusText,
                            statusColor: viewModel.sunlightStatusColor,
                            idealRange: 55...94
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "栄養",
                            value: viewModel.flower.nutrition,
                            color: .green,
                            systemImage: "leaf.fill",
                            statusText: viewModel.nutritionStatusText,
                            statusColor: viewModel.nutritionStatusColor,
                            idealRange: 55...90
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "ストレス",
                            value: viewModel.stressPercent,
                            color: .red,
                            systemImage: "exclamationmark.triangle.fill",
                            statusText: viewModel.stressStatusText,
                            statusColor: viewModel.stressStatusColor,
                            idealRange: 0...27
                        )
                        Divider().padding(.vertical, 4)
                        StatChipView(
                            title: "枯れリスク",
                            value: viewModel.deathRiskPercent,
                            color: .purple,
                            systemImage: "flame.fill",
                            statusText: viewModel.deathRiskStatusText,
                            statusColor: viewModel.deathRiskStatusColor,
                            idealRange: 0...34
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)

                    ActionButtonsView(
                        isDead: viewModel.isDead,
                        isFullyBloomed: viewModel.isFullyBloomed,
                        canWater: viewModel.canWaterToday,
                        canGiveSunlight: viewModel.canGiveSunlightToday,
                        canFeed: viewModel.canFeedToday,
                        isCompact: isCompact,
                        onReplant: viewModel.resetFlower,
                        onWater: waterFlowerWithEffect,
                        onSunlight: giveLightWithEffect,
                        onFeed: feedFlowerWithEffect
                    )

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isCompact ? 8 : 12)
                .padding(.bottom, isCompact ? 4 : 10)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            viewModel.applyElapsedTimeIfNeeded()

            Task {
                await viewModel.refreshRealWeather()
            }
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
    }

    private func waterFlowerWithEffect() {
        guard viewModel.canWaterToday else {
            return
        }

        wateringEffectTrigger += 1
        viewModel.waterFlower()
    }

    private func giveLightWithEffect() {
        guard viewModel.canGiveSunlightToday else {
            return
        }

        lightEffectTrigger += 1
        viewModel.giveSunlight()
    }

    private func feedFlowerWithEffect() {
        guard viewModel.canFeedToday else {
            return
        }

        fertilizerEffectTrigger += 1
        viewModel.feedFlower()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
