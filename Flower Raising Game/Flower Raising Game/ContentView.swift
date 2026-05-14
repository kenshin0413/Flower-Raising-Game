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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.92),
                    Color(red: 0.90, green: 0.98, blue: 0.88),
                    Color(red: 0.88, green: 0.96, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                let isCompact = geometry.size.height < 760
                let horizontalPadding: CGFloat = 20
                let verticalSpacing: CGFloat = isCompact ? 5 : 7
                let verticalPadding: CGFloat = 22
                let headerHeight: CGFloat = isCompact ? 88 : 98
                let growthCardHeight: CGFloat = 46
                let adviceCardHeight: CGFloat = 34
                let statCardHeight: CGFloat = 54
                let actionCardHeight: CGFloat = 82
                let spacingHeight = verticalSpacing * 5
                let reservedHeight = verticalPadding + headerHeight + growthCardHeight + adviceCardHeight + statCardHeight + actionCardHeight + spacingHeight
                let availablePlantHeight = geometry.size.height - reservedHeight
                let plantHeight = min(max(availablePlantHeight, 285), 590)

                VStack(spacing: verticalSpacing) {
                    GardenHeaderView(
                        weatherEmoji: viewModel.weatherDisplayEmoji,
                        weatherName: viewModel.weatherDisplayName,
                        temperatureText: viewModel.temperatureText,
                        humidityText: viewModel.humidityText,
                        windSpeedText: viewModel.windSpeedText,
                        careStreakText: viewModel.careStreakText
                    )

                    FlowerHeroView(
                        flower: viewModel.flower,
                        plantImageName: viewModel.plantImageName,
                        growthPercentText: viewModel.growthPercentText,
                        imageHeight: plantHeight,
                        windSpeed: viewModel.currentWindSpeed ?? viewModel.flower.lastWindSpeed
                    )

                    GrowthStageCardView(
                        stageName: viewModel.stageName,
                        stageProgress: viewModel.visualStageProgressPercent
                    )

                    CareAdviceView(
                        text: viewModel.careAdviceText,
                        systemImage: viewModel.careAdviceSystemImage,
                        color: viewModel.careAdviceColor
                    )

                    HStack(spacing: 0) {
                        StatChipView(title: "水分", value: viewModel.flower.water, color: .cyan, systemImage: "drop.fill")
                        Divider().padding(.vertical, 4)
                        StatChipView(title: "日光", value: viewModel.flower.sunlight, color: .orange, systemImage: "sun.max.fill")
                        Divider().padding(.vertical, 4)
                        StatChipView(title: "栄養", value: viewModel.flower.nutrition, color: .green, systemImage: "leaf.fill")
                        Divider().padding(.vertical, 4)
                        StatChipView(title: "ストレス", value: viewModel.stressPercent, color: .red, systemImage: "exclamationmark.triangle.fill")
                        Divider().padding(.vertical, 4)
                        StatChipView(title: "枯れリスク", value: viewModel.deathRiskPercent, color: .purple, systemImage: "flame.fill")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)

                    ActionButtonsView(
                        isDead: viewModel.isDead,
                        canWater: viewModel.canWaterToday,
                        canGiveSunlight: viewModel.canGiveSunlightToday,
                        canFeed: viewModel.canFeedToday,
                        onReplant: viewModel.resetFlower,
                        onWater: viewModel.waterFlower,
                        onSunlight: viewModel.giveSunlight,
                        onFeed: viewModel.feedFlower
                    )

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 10)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
