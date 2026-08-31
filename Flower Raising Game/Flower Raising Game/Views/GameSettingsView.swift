import SwiftUI

struct GameSettingsView: View {
    @ObservedObject var backgroundMusicService: BackgroundMusicService
    @ObservedObject var flowerGardenViewModel: FlowerGardenViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsSurface {
                VStack(alignment: .leading, spacing: 18) {
                    SettingsHeroHeader(
                        title: "設定",
                        subtitle: "音、植物、育成記録をまとめて管理",
                        systemImage: "gearshape.fill"
                    )

                    NavigationLink {
                        BackgroundMusicSettingsView(backgroundMusicService: backgroundMusicService)
                    } label: {
                        SettingsMenuCard(
                            title: "BGM",
                            subtitle: backgroundMusicService.selectedTrack.title,
                            footnote: backgroundMusicService.isEnabled ? "再生中" : "停止中",
                            systemImage: "music.note",
                            tint: .green
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PlantAndVaseSelectionView(viewModel: flowerGardenViewModel)
                    } label: {
                        SettingsMenuCard(
                            title: "植物と花瓶",
                            subtitle: flowerGardenViewModel.selectedPlantSpecies.name,
                            footnote: "育てる植物を選択",
                            systemImage: "camera.macro",
                            tint: .mint
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PlantEncyclopediaView(viewModel: flowerGardenViewModel)
                    } label: {
                        SettingsMenuCard(
                            title: "育成済み植物図鑑",
                            subtitle: "育てた植物の記録",
                            footnote: "準備中",
                            systemImage: "book.closed.fill",
                            tint: .brown
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WidgetSetupGuideView()
                    } label: {
                        SettingsMenuCard(
                            title: "ホーム画面ウィジェット",
                            subtitle: "花の機嫌をいつでも確認",
                            footnote: "追加方法を見る",
                            systemImage: "rectangle.3.group.fill",
                            tint: .orange
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.76))
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.74))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("閉じる")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct BackgroundMusicSettingsView: View {
    @ObservedObject var backgroundMusicService: BackgroundMusicService

    var body: some View {
        SettingsSurface {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeroHeader(
                    title: "BGM",
                    subtitle: backgroundMusicService.selectedTrack.subtitle,
                    systemImage: "music.quarternote.3"
                )

                SettingsToggleCard(
                    title: "BGM",
                    subtitle: backgroundMusicService.isEnabled ? "庭のBGMを再生しています" : "BGMは停止中です",
                    systemImage: backgroundMusicService.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    isOn: backgroundMusicService.isEnabled,
                    tint: .green,
                    onToggle: {
                        backgroundMusicService.toggle()
                    }
                )

                VStack(alignment: .leading, spacing: 10) {
                    SettingsSectionLabel("曲を選択")

                    ForEach(backgroundMusicService.tracks) { track in
                        MusicTrackCard(
                            track: track,
                            isSelected: backgroundMusicService.selectedTrack == track,
                            isEnabled: backgroundMusicService.isEnabled
                        ) {
                            backgroundMusicService.selectTrack(track)
                        }
                    }
                }
            }
        }
        .navigationTitle("BGM")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct PlantAndVaseSelectionView: View {
    @ObservedObject var viewModel: FlowerGardenViewModel
    @State private var pendingPlantSelection: PlantSpecies?
    @State private var isPlantChangeAlertPresented = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        SettingsSurface {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeroHeader(
                    title: "植物と花瓶",
                    subtitle: "\(viewModel.selectedPlantSpecies.name)を育成中",
                    systemImage: "camera.macro"
                )

                VStack(alignment: .leading, spacing: 10) {
                    SettingsSectionLabel("植物")

                    PreferenceInfoCard(
                        title: viewModel.selectedPlantSpecies.name,
                        subtitle: viewModel.plantPreferenceSummaryText,
                        detail: viewModel.selectedPlantSpecies.preference.careHint,
                        systemImage: "leaf.fill",
                        tint: .green
                    )

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.availablePlantSpecies) { plant in
                            let isUnlocked = viewModel.isPlantUnlocked(plant)

                            PlantSelectionCard(
                                plant: plant,
                                isSelected: viewModel.selectedPlantSpecies.id == plant.id,
                                isUnlocked: isUnlocked
                            ) {
                                if isUnlocked {
                                    selectPlant(plant)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SettingsSectionLabel("花瓶")

                    PreferenceInfoCard(
                        title: viewModel.selectedVaseStyle.name,
                        subtitle: viewModel.vaseEffectSummaryText,
                        detail: viewModel.selectedVaseStyle.effect.detail,
                        systemImage: "shippingbox.fill",
                        tint: .orange
                    )

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.availableVaseStyles) { vase in
                            let isUnlocked = viewModel.isVaseUnlocked(vase)

                            VaseSelectionCard(
                                vase: vase,
                                isSelected: viewModel.selectedVaseStyle == vase,
                                isUnlocked: isUnlocked
                            ) {
                                if isUnlocked {
                                    viewModel.selectVaseStyle(vase)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("植物と花瓶")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("植物を変更しますか？", isPresented: $isPlantChangeAlertPresented) {
            Button("キャンセル", role: .cancel) {
                pendingPlantSelection = nil
            }
            Button("変更する", role: .destructive) {
                guard let pendingPlantSelection else {
                    return
                }

                viewModel.replaceCurrentPlantWithNewSeed(pendingPlantSelection)
                self.pendingPlantSelection = nil
            }
        } message: {
            Text("今育てている植物の成長がリセットされ、\(pendingPlantSelection?.name ?? "選択した植物")を最初から育てます。")
        }
    }

    private func selectPlant(_ plant: PlantSpecies) {
        if viewModel.needsPlantChangeConfirmation(for: plant) {
            pendingPlantSelection = plant
            isPlantChangeAlertPresented = true
        } else {
            viewModel.selectPlantSpecies(plant)
        }
    }
}

private struct PlantEncyclopediaView: View {
    @ObservedObject var viewModel: FlowerGardenViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        SettingsSurface {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeroHeader(
                    title: "図鑑",
                    subtitle: "育てた植物の記録",
                    systemImage: "book.closed.fill"
                )

                SettingsSectionLabel("植物図鑑")

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.availablePlantSpecies) { plant in
                        let records = viewModel.bloomRecords.filter { $0.plantID == plant.id }
                        PlantEncyclopediaSquareCard(
                            plant: plant,
                            latestRecord: records.first,
                            bloomCount: records.count,
                            isUnlocked: viewModel.isPlantUnlocked(plant)
                        )
                    }
                }
            }
        }
        .navigationTitle("図鑑")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SettingsSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.99, blue: 0.95),
                    Color(red: 0.98, green: 0.95, blue: 0.87),
                    Color(red: 0.87, green: 0.97, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

private struct SettingsHeroHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.green)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.70))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.82))

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.58))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }
}

private struct SettingsMenuCard: View {
    let title: String
    let subtitle: String
    let footnote: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.82))

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.56))
                    .lineLimit(1)

                Text(footnote)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.brown.opacity(0.42))
        }
        .padding(16)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: .brown.opacity(0.08), radius: 12, y: 6)
    }
}

private struct SettingsToggleCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isOn: Bool
    let tint: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.brown.opacity(0.82))

                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.brown.opacity(0.56))
                        .lineLimit(2)
                }

                Spacer()

                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? tint.opacity(0.70) : .brown.opacity(0.18))
                        .frame(width: 52, height: 30)

                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .padding(.horizontal, 3)
                        .shadow(color: .brown.opacity(0.12), radius: 4, y: 2)
                }
                .frame(width: 52, height: 30)
            }
            .padding(16)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.62), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MusicTrackCard: View {
    let track: BackgroundMusicTrack
    let isSelected: Bool
    let isEnabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? .green.opacity(0.18) : .white.opacity(0.58))
                        .frame(width: 46, height: 46)

                    Image(systemName: isSelected && isEnabled ? "speaker.wave.2.fill" : "music.note")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(isSelected ? .green : .brown.opacity(0.52))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.brown.opacity(0.82))

                    Text(track.subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.brown.opacity(0.54))
                }

                Spacer()

                SelectionMark(isSelected: isSelected)
            }
            .padding(14)
            .background(isSelected ? .white.opacity(0.82) : .white.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? .green.opacity(0.34) : .white.opacity(0.54), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PreferenceInfoCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.82))

                Text(subtitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(detail)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.56))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct PlantSelectionCard: View {
    let plant: PlantSpecies
    let isSelected: Bool
    let isUnlocked: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.58))
                        .frame(height: 104)

                    Image(plant.seedImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 72)
                        .frame(maxWidth: .infinity, maxHeight: 104)
                        .padding(.top, 14)
                        .scaleEffect(seedImageScale)
                        .offset(y: seedImageVerticalOffset)
                        .saturation(isUnlocked ? 1 : 0.18)
                        .opacity(isUnlocked ? 1 : 0.44)
                        .allowsHitTesting(false)

                    if isUnlocked {
                        SelectionMark(isSelected: isSelected)
                            .padding(8)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.brown.opacity(0.58))
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                .frame(height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 3) {
                    Text(plant.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isUnlocked ? .brown.opacity(0.82) : .brown.opacity(0.46))
                        .lineLimit(1)

                    Text(statusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Text(plant.preference.summary)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.brown.opacity(isUnlocked ? 0.50 : 0.34))
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? .white.opacity(0.84) : .white.opacity(isUnlocked ? 0.58 : 0.42))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? .green.opacity(0.36) : .white.opacity(isUnlocked ? 0.52 : 0.32), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .disabled(!isUnlocked)
    }

    private var seedImageScale: CGFloat {
        switch plant.id {
        case "rose":
            return 7.4
        case "cactus":
            return 3.0
        case "dahlia":
            return 1.8
        default:
            return 1
        }
    }

    private var seedImageVerticalOffset: CGFloat {
        switch plant.id {
        case "rose":
            return -34
        case "cactus":
            return -70
        case "dahlia":
            return -8
        default:
            return 0
        }
    }

    private var statusText: String {
        if !isUnlocked {
            switch plant.id {
            case "rose":
                return "ライト5回か種袋"
            case "morning-glory":
                return "10日か種袋で解放"
            default:
                return "種袋で解放"
            }
        }

        return isSelected ? "選択中" : "育てる"
    }

    private var statusColor: Color {
        if !isUnlocked {
            return .brown.opacity(0.46)
        }

        return isSelected ? .green : .brown.opacity(0.52)
    }
}

private struct VaseSelectionCard: View {
    let vase: VaseStyle
    let isSelected: Bool
    let isUnlocked: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.58))
                        .frame(height: 104)

                    Image(vase.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 82)
                        .frame(maxWidth: .infinity, maxHeight: 104)
                        .padding(.top, 10)
                        .saturation(isUnlocked ? 1 : 0.16)
                        .opacity(isUnlocked ? 1 : 0.42)

                    if isUnlocked {
                        SelectionMark(isSelected: isSelected)
                            .padding(8)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 25, height: 25)
                            .background(.brown.opacity(0.46))
                            .clipShape(Circle())
                            .padding(8)
                    }
                }

                VStack(spacing: 3) {
                    Text(vase.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isUnlocked ? .brown.opacity(0.82) : .brown.opacity(0.46))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(statusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)

                    Text(vase.effect.summary)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.brown.opacity(isUnlocked ? 0.50 : 0.34))
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? .white.opacity(0.84) : .white.opacity(isUnlocked ? 0.58 : 0.42))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? .green.opacity(0.36) : .white.opacity(isUnlocked ? 0.52 : 0.32), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private var statusText: String {
        if !isUnlocked {
            return vase.id == "blue-gloss" ? "15日か鉢箱で解放" : "鉢箱で解放"
        }

        return isSelected ? "選択中" : "変更する"
    }

    private var statusColor: Color {
        if !isUnlocked {
            return .brown.opacity(0.46)
        }

        return isSelected ? .green : .brown.opacity(0.52)
    }
}

private struct EmptyEncyclopediaCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.macro")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.green)
                .frame(width: 54, height: 54)
                .background(.green.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("まだ開花記録はありません")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.brown.opacity(0.82))

            Text("開花するとここに記録されます")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.brown.opacity(0.54))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.white.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PlantEncyclopediaSquareCard: View {
    let plant: PlantSpecies
    let latestRecord: PlantBloomRecord?
    let bloomCount: Int
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.55))

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .offset(x: imageOffsetX)
                    .saturation(isBloomed ? 1 : 0)
                    .brightness(isBloomed ? 0 : -0.42)
                    .contrast(isBloomed ? 1 : 1.8)
                    .opacity(isUnlocked ? 1 : 0.46)

                badge
                    .padding(8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)

            Text(titleText)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isUnlocked ? .brown.opacity(0.84) : .brown.opacity(0.46))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(statusText)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(detailText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.brown.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(10)
        .background(.white.opacity(isUnlocked ? 0.72 : 0.48))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isBloomed ? .green.opacity(0.30) : .white.opacity(0.50), lineWidth: 1)
        )
        .shadow(color: .brown.opacity(0.08), radius: 10, y: 5)
    }

    private var isBloomed: Bool {
        latestRecord != nil
    }

    private var imageName: String {
        latestRecord?.bloomImageName ?? plant.normalStageImageNames.last ?? plant.seedImageName
    }

    private var imageOffsetX: CGFloat {
        switch plant.id {
        case "sunflower", "morning-glory":
            return -18
        default:
            return 0
        }
    }

    private var titleText: String {
        isUnlocked ? plant.name : "？？？"
    }

    private var statusText: String {
        if let latestRecord {
            return "\(latestRecord.daysToBloom)日で開花"
        }

        return isUnlocked ? "未開花" : "未開放"
    }

    private var detailText: String {
        if let latestRecord {
            return bloomCount > 1 ? "\(dateText(latestRecord.bloomedAt))・\(bloomCount)回" : dateText(latestRecord.bloomedAt)
        }

        return isUnlocked ? plant.preference.summary : unlockHint
    }

    private var unlockHint: String {
        plant.id == "morning-glory" ? "10日か種袋で解放" : "種袋で解放"
    }

    private var statusColor: Color {
        if isBloomed {
            return .green
        }

        return isUnlocked ? .orange : .brown.opacity(0.46)
    }

    @ViewBuilder
    private var badge: some View {
        if let latestRecord {
            Text(latestRecord.careRank.rawValue)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(rankColor(latestRecord.careRank).opacity(0.88))
                .clipShape(Circle())
        } else {
            Image(systemName: isUnlocked ? "questionmark" : "lock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background((isUnlocked ? Color.orange : Color.brown).opacity(0.62))
                .clipShape(Circle())
        }
    }

    private func rankColor(_ rank: BloomCareRank) -> Color {
        switch rank {
        case .s:
            return .yellow
        case .a:
            return .red
        case .b:
            return .blue
        case .c:
            return .green
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

private struct BloomRecordSquareCard: View {
    let record: PlantBloomRecord

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.55))

                Image(record.bloomImageName)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .offset(x: -18)

                Text(record.careRank.rawValue)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(rankColor.opacity(0.88))
                    .clipShape(Circle())
                    .padding(8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)

            Text(record.plantName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.brown.opacity(0.84))
                .lineLimit(1)

            Text("\(record.daysToBloom)日で開花")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.green)
                .lineLimit(1)

            Text(dateText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.brown.opacity(0.52))
                .lineLimit(1)
        }
        .padding(10)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.58), lineWidth: 1)
        )
        .shadow(color: .brown.opacity(0.08), radius: 10, y: 5)
    }

    private var rankColor: Color {
        switch record.careRank {
        case .s:
            return .yellow
        case .a:
            return .red
        case .b:
            return .blue
        case .c:
            return .green
        }
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: record.bloomedAt)
    }
}

private struct SelectionMark: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(isSelected ? .green : .brown.opacity(0.28))
    }
}

private struct SettingsSectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.brown.opacity(0.62))
            .padding(.horizontal, 2)
    }
}

#Preview {
    GameSettingsView(
        backgroundMusicService: BackgroundMusicService(),
        flowerGardenViewModel: FlowerGardenViewModel()
    )
}
