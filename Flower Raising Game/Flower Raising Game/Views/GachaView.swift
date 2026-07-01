import SwiftUI

struct GachaView: View {
    @ObservedObject var viewModel: FlowerGardenViewModel
    @StateObject private var rewardedAdService = RewardedAdService()
    @Environment(\.dismiss) private var dismiss

    @State private var mode: GachaMode = .seed
    @State private var phase: GachaPhase = .ready
    @State private var revealedPlant: PlantSpecies?
    @State private var revealedVase: VaseStyle?
    @State private var packetShake = false
    @State private var seedDrop = false
    @State private var glowPulse = false
    @State private var pendingPlantSelection: PlantSpecies?
    @State private var isPlantChangeAlertPresented = false
    @State private var isSelectionPresented = false
    @State private var isGachaUnavailableAlertPresented = false
    @State private var gachaAlertTitle = "開封できません"
    @State private var unavailableGachaMessage = ""
    @State private var isRewardedTicketCelebrationPresented = false
    @State private var rewardedTicketCelebrationID = 0

    fileprivate enum GachaMode: String, CaseIterable {
        case seed = "種袋"
        case vase = "鉢箱"

        var systemImage: String {
            switch self {
            case .seed:
                return "leaf.fill"
            case .vase:
                return "shippingbox.fill"
            }
        }

        var title: String {
            switch self {
            case .seed:
                return "種袋をひらく"
            case .vase:
                return "鉢箱をひらく"
            }
        }

        var subtitle: String {
            switch self {
            case .seed:
                return "今日の庭に届いた小さな種"
            case .vase:
                return "花に似合う鉢をひとつ"
            }
        }
    }

    private enum GachaPhase {
        case ready
        case opening
        case revealed
    }

    var body: some View {
        ZStack {
            GachaBackgroundView()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        modePicker

                        openingStage
                            .padding(.top, 4)

                        actionArea
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 26)
                }
            }

            if rewardedAdService.isLoading {
                GachaAdLoadingOverlay()
                    .zIndex(20)
            }

            if isRewardedTicketCelebrationPresented {
                RewardedGachaTicketCelebrationOverlay(
                    id: rewardedTicketCelebrationID,
                    ticketCountText: viewModel.gachaTicketText,
                    mode: mode,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRewardedTicketCelebrationPresented = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(30)
            }
        }
        .onChange(of: mode) { _, _ in
            resetOpening()
        }
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
                dismiss()
            }
        } message: {
            Text("今育てている植物の成長がリセットされ、\(pendingPlantSelection?.name ?? "選択した植物")を最初から育てます。")
        }
        .alert(gachaAlertTitle, isPresented: $isGachaUnavailableAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(unavailableGachaMessage)
        }
        .sheet(isPresented: $isSelectionPresented) {
            NavigationStack {
                PlantAndVaseSelectionView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isSelectionPresented = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.brown.opacity(0.76))
                                    .frame(width: 34, height: 34)
                                    .background(.white.opacity(0.74))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ガーデン便")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.86))

                Text("届いた包みをそっと開ける")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.56))
            }

            Spacer()

            Label("所持 \(viewModel.gachaTicketText)", systemImage: "ticket.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.green.opacity(0.86))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.66))
                .clipShape(Capsule())

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.66))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.66))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(GachaMode.allCases, id: \.self) { item in
                Button {
                    mode = item
                } label: {
                    Label(item.rawValue, systemImage: item.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(mode == item ? .white : .brown.opacity(0.68))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == item ? .green.opacity(0.82) : .white.opacity(0.56))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var openingStage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 5) {
                Text(mode.title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.86))

                Text(mode.subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.55))
            }

            ZStack {
                Circle()
                    .fill(.white.opacity(0.30))
                    .frame(width: 260, height: 260)
                    .blur(radius: 8)

                Circle()
                    .stroke(.white.opacity(0.34), lineWidth: 1)
                    .frame(width: glowPulse ? 258 : 218, height: glowPulse ? 258 : 218)
                    .opacity(phase == .ready ? 0.3 : 0.8)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glowPulse)

                ForEach(0..<12, id: \.self) { index in
                    GachaSparkle(index: index, isActive: phase != .ready)
                }

                if mode == .seed {
                    seedOpeningVisual
                } else {
                    vaseOpeningVisual
                }
            }
            .frame(height: 292)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .background(.white.opacity(0.44))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.50), lineWidth: 1)
        )
    }

    private var seedOpeningVisual: some View {
        ZStack {
            SeedParticleTrail(isActive: seedDrop)

            if phase != .ready, let revealedPlant {
                ResultHaloView(color: .green)
                    .offset(y: -78)
                    .opacity(phase == .revealed ? 1 : 0.35)

                Image(revealedPlant.seedImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .offset(
                        x: phase == .revealed ? 0 : -18,
                        y: phase == .revealed ? -82 : -10
                    )
                    .scaleEffect(phase == .revealed ? 1 : 0.34)
                    .opacity(phase == .revealed ? 1 : 0.54)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.72, dampingFraction: 0.82), value: phase)
            }

            SeedPacketView(isOpen: phase != .ready)
                .rotationEffect(.degrees(phase == .opening ? -2 : 0))
                .offset(x: phase == .ready ? 0 : -10, y: phase == .revealed ? 250 : -16)
                .scaleEffect(phase == .ready ? 1 : 0.94)
                .opacity(phase == .revealed ? 0.0 : 1.0)
                .animation(.spring(response: 0.42, dampingFraction: 0.78), value: phase)

            if phase == .revealed, let revealedPlant {
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text("届いた種")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.48))

                        Text(revealedPlant.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.84))
                    }

                    HStack(spacing: 10) {
                        Button("もう一度") {
                            resetOpening()
                        }
                        .buttonStyle(GachaSecondaryButtonStyle())

                        Button("保管") {
                            isSelectionPresented = true
                        }
                        .buttonStyle(GachaPrimaryButtonStyle(color: .green))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.white.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.56), lineWidth: 1)
                )
                .offset(y: 98)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var vaseOpeningVisual: some View {
        ZStack {
            if phase != .ready, let revealedVase {
                ResultHaloView(color: .orange)
                    .offset(y: -72)
                    .opacity(phase == .revealed ? 1 : 0.45)

                Image(revealedVase.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118, height: 118)
                    .offset(y: phase == .revealed ? -76 : 18)
                    .scaleEffect(phase == .revealed ? 1 : 0.72)
                    .opacity(phase == .revealed ? 1 : 0.62)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.72, dampingFraction: 0.80), value: phase)
            }

            VaseBoxView(isOpen: phase != .ready)
                .rotationEffect(.degrees(phase == .opening ? -2 : 0))
                .offset(y: phase == .revealed ? 250 : 36)
                .opacity(phase == .revealed ? 0.0 : 1.0)
                .animation(.spring(response: 0.46, dampingFraction: 0.78), value: phase)

            if phase == .revealed, let revealedVase {
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text("届いた鉢")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.48))

                        Text(revealedVase.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.84))
                    }

                    HStack(spacing: 10) {
                        Button("もう一度") {
                            resetOpening()
                        }
                        .buttonStyle(GachaSecondaryButtonStyle())

                        Button("保管") {
                            isSelectionPresented = true
                        }
                        .buttonStyle(GachaPrimaryButtonStyle(color: .orange))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.white.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.56), lineWidth: 1)
                )
                .offset(y: 98)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        switch phase {
        case .ready, .opening:
            VStack(spacing: 9) {
                Button {
                    openGacha()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 17, weight: .bold))

                        Text(openButtonTitle)
                            .font(.system(size: 17, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green.opacity(isOpenButtonEnabled ? 0.86 : 0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .green.opacity(isOpenButtonEnabled ? 0.18 : 0.06), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!isOpenButtonEnabled)

                Text(gachaTicketRequirementMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                RewardedGachaTicketButton(
                    title: viewModel.rewardedGachaTicketButtonTitle,
                    message: viewModel.rewardedGachaTicketMessage,
                    isEnabled: viewModel.canWatchAdForGachaTicketToday && !rewardedAdService.isLoading,
                    mode: mode,
                    action: showRewardedTicketAd
                )
                .padding(.top, 4)
            }

        case .revealed:
            EmptyView()
        }
    }

    private var resultCard: some View {
        VStack(spacing: 14) {
            Text("届いたもの")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.brown.opacity(0.50))

            if let revealedPlant, mode == .seed {
                GachaResultSummary(
                    imageName: revealedPlant.seedImageName,
                    title: revealedPlant.name,
                    subtitle: "この種から育てられます",
                    accent: .green
                )

                HStack(spacing: 10) {
                    Button("もう一度") {
                        resetOpening()
                    }
                    .buttonStyle(GachaSecondaryButtonStyle())

                    Button("保管") {
                        isSelectionPresented = true
                    }
                    .buttonStyle(GachaPrimaryButtonStyle(color: .green))
                }
            }

            if let revealedVase, mode == .vase {
                GachaResultSummary(
                    imageName: revealedVase.imageName,
                    title: revealedVase.name,
                    subtitle: "今の花瓶として使えます",
                    accent: .orange
                )

                HStack(spacing: 10) {
                    Button("もう一度") {
                        resetOpening()
                    }
                    .buttonStyle(GachaSecondaryButtonStyle())

                    Button("保管") {
                        isSelectionPresented = true
                    }
                    .buttonStyle(GachaPrimaryButtonStyle(color: .orange))
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.56), lineWidth: 1)
        )
    }

    private func openGacha() {
        guard phase != .opening else {
            return
        }

        let seedCandidates = availableSeedCandidates
        let vaseCandidates = availableVaseCandidates
        if mode == .seed, seedCandidates.isEmpty {
            gachaAlertTitle = "全部保管済みです"
            unavailableGachaMessage = "今出せる種はすべて保管済みです。新しい種が追加されたらまた開けられます。"
            isGachaUnavailableAlertPresented = true
            return
        }

        if mode == .vase, vaseCandidates.isEmpty {
            gachaAlertTitle = "全部保管済みです"
            unavailableGachaMessage = "今出せる鉢はすべて保管済みです。新しい鉢が追加されたらまた開けられます。"
            isGachaUnavailableAlertPresented = true
            return
        }

        guard viewModel.consumeGachaTicketsForDraw(isSeed: mode == .seed) else {
            gachaAlertTitle = "チケットが足りません"
            unavailableGachaMessage = "開封にはチケットが\(viewModel.gachaTicketCostText)必要です。毎日ログインすると1枚もらえます。現在は\(viewModel.gachaTicketText)です。"
            isGachaUnavailableAlertPresented = true
            return
        }

        phase = .opening
        packetShake.toggle()
        glowPulse = true

        if mode == .seed {
            revealedPlant = nil
            seedDrop = false
            let result = randomPlantResult(from: seedCandidates)
            revealedPlant = result
            viewModel.storeGachaPlantResult(result)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    seedDrop = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.78)) {
                    phase = .revealed
                }
            }
        } else {
            revealedVase = nil
            let result = randomVaseResult(from: vaseCandidates)
            revealedVase = result
            viewModel.storeGachaVaseResult(result)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.76)) {
                    phase = .revealed
                }
            }
        }
    }

    private var availableSeedCandidates: [PlantSpecies] {
        viewModel.availablePlantSpecies.filter { plant in
            !viewModel.isPlantUnlocked(plant)
        }
    }

    private var availableVaseCandidates: [VaseStyle] {
        viewModel.availableVaseStyles.filter { vase in
            !viewModel.isVaseUnlocked(vase)
        }
    }

    private var isOpenButtonEnabled: Bool {
        phase != .opening && viewModel.canOpenGacha(isSeed: mode == .seed)
    }

    private var openButtonTitle: String {
        if viewModel.isFirstGachaFree(isSeed: mode == .seed) {
            return mode == .seed ? "初回無料で種袋を開ける" : "初回無料で鉢箱を開ける"
        }

        guard viewModel.canOpenGacha(isSeed: mode == .seed) else {
            return "あと\(viewModel.gachaTicketShortfallText)で開封"
        }

        return mode == .seed
            ? "\(viewModel.gachaTicketCostText)消費して種袋を開ける"
            : "\(viewModel.gachaTicketCostText)消費して鉢箱を開ける"
    }

    private var gachaTicketRequirementMessage: String {
        if viewModel.isFirstGachaFree(isSeed: mode == .seed) {
            return "\(mode.rawValue)は初回だけ無料・所持 \(viewModel.gachaTicketText)"
        }

        if viewModel.canOpenGacha(isSeed: mode == .seed) {
            return "1回\(viewModel.gachaTicketCostText)・所持 \(viewModel.gachaTicketText)"
        }

        return "1回\(viewModel.gachaTicketCostText)必要・所持 \(viewModel.gachaTicketText)・ログインと広告で集められます"
    }

    private func showRewardedTicketAd() {
        guard viewModel.canWatchAdForGachaTicketToday,
              !rewardedAdService.isLoading else {
            return
        }

        Task {
            let didEarnReward = await rewardedAdService.showRewardedAd()
            guard didEarnReward,
                  viewModel.grantRewardedGachaTicket() else {
                return
            }

            rewardedTicketCelebrationID += 1
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                isRewardedTicketCelebrationPresented = true
            }
        }
    }

    private func resetOpening() {
        phase = .ready
        revealedPlant = nil
        revealedVase = nil
        pendingPlantSelection = nil
        seedDrop = false
        glowPulse = false
        packetShake = false
    }

    private func selectRevealedPlant(_ plant: PlantSpecies) {
        if viewModel.needsPlantChangeConfirmation(for: plant) {
            pendingPlantSelection = plant
            isPlantChangeAlertPresented = true
        } else if viewModel.flower.plantID == plant.id {
            dismiss()
        } else {
            viewModel.selectPlantSpecies(plant)
            dismiss()
        }
    }

    private func randomPlantResult(from plants: [PlantSpecies]) -> PlantSpecies {
        let defaultPlant = PlantSpeciesCatalog.plant(for: nil)
        guard !plants.isEmpty else {
            return defaultPlant
        }

        return plants.randomElement() ?? plants[0]
    }

    private func randomVaseResult(from vases: [VaseStyle]) -> VaseStyle {
        guard !vases.isEmpty else {
            return VaseStyleCatalog.vase(for: nil)
        }

        return vases.randomElement() ?? vases[0]
    }
}

private struct GachaBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.99, blue: 0.93),
                Color(red: 0.99, green: 0.95, blue: 0.84),
                Color(red: 0.86, green: 0.97, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    for index in 0..<18 {
                        let x = size.width * (0.08 + CGFloat((index * 19) % 83) / 100)
                        let baseY = size.height * (0.08 + CGFloat((index * 31) % 78) / 100)
                        let y = baseY + CGFloat(sin(time * 0.35 + Double(index))) * 8
                        let opacity = 0.12 + 0.10 * CGFloat(sin(time * 0.5 + Double(index * 2)))
                        let rect = CGRect(x: x, y: y, width: 5, height: 5)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(Double(opacity))))
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct SeedPacketView: View {
    let isOpen: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.94, green: 0.73, blue: 0.43),
                            Color(red: 0.78, green: 0.48, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 136, height: 164)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.30), lineWidth: 1)
                )

            VStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.green.opacity(0.82))
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.42))
                    .clipShape(Circle())

                Text("SEED")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))

                Capsule()
                    .fill(.white.opacity(0.32))
                    .frame(width: 74, height: 5)
            }
            .offset(y: 13)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.98, green: 0.82, blue: 0.50))
                .frame(width: 142, height: 38)
                .rotationEffect(.degrees(isOpen ? -24 : 0), anchor: .leading)
                .offset(y: -80)
                .shadow(color: .brown.opacity(isOpen ? 0.16 : 0), radius: 8, y: 4)
        }
        .shadow(color: .brown.opacity(0.16), radius: 18, y: 10)
    }
}

private struct VaseBoxView: View {
    let isOpen: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.78, green: 0.62, blue: 0.42),
                            Color(red: 0.56, green: 0.38, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 154, height: 124)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                )

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(width: 18, height: 124)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.84, green: 0.68, blue: 0.47))
                .frame(width: 164, height: 48)
                .rotationEffect(.degrees(isOpen ? -28 : 0), anchor: .leading)
                .offset(y: -70)
                .shadow(color: .brown.opacity(isOpen ? 0.14 : 0), radius: 8, y: 4)

            Image(systemName: "shippingbox.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white.opacity(0.76))
                .offset(y: 14)
        }
        .shadow(color: .brown.opacity(0.16), radius: 18, y: 10)
    }
}

private struct SoilLandingView: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.32, green: 0.17, blue: 0.08),
                            Color(red: 0.18, green: 0.09, blue: 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 128, height: 34)
                .overlay(
                    Ellipse()
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )

            ForEach(0..<18, id: \.self) { index in
                Circle()
                    .fill(.brown.opacity(0.45))
                    .frame(width: CGFloat(2 + index % 3), height: CGFloat(2 + index % 3))
                    .offset(
                        x: CGFloat((index * 17) % 94) - 47,
                        y: CGFloat((index * 11) % 18) - 9
                    )
            }
        }
        .shadow(color: .brown.opacity(0.12), radius: 8, y: 4)
    }
}

private struct SeedParticleTrail: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.14, blue: 0.07),
                                Color(red: 0.54, green: 0.35, blue: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat(6 + index % 2), height: CGFloat(9 + index % 3))
                    .rotationEffect(.degrees(Double(index * 23)))
                    .offset(
                        x: isActive ? CGFloat(index * 8 - 22) : -28,
                        y: isActive ? CGFloat(-96 - index * 5) : -8
                    )
                    .opacity(isActive ? 0.65 : 0)
                    .animation(
                        .interpolatingSpring(stiffness: 80, damping: 10)
                            .delay(Double(index) * 0.055),
                        value: isActive
                    )
            }
        }
    }
}

private struct GachaSparkle: View {
    let index: Int
    let isActive: Bool

    private var angle: Double {
        Double(index) / 12 * .pi * 2
    }

    var body: some View {
        Circle()
            .fill(index.isMultiple(of: 3) ? .yellow.opacity(0.72) : .white.opacity(0.78))
            .frame(width: CGFloat(4 + index % 3), height: CGFloat(4 + index % 3))
            .offset(
                x: cos(angle) * (isActive ? 116 : 72),
                y: sin(angle) * (isActive ? 108 : 64)
            )
            .opacity(isActive ? 1 : 0.22)
            .animation(.spring(response: 0.70, dampingFraction: 0.74).delay(Double(index) * 0.025), value: isActive)
    }
}

private struct ResultHaloView: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 170, height: 170)
                .blur(radius: 8)

            Circle()
                .stroke(.white.opacity(0.58), lineWidth: 1)
                .frame(width: 148, height: 148)
        }
    }
}

private struct GachaResultSummary: View {
    let imageName: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .padding(8)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.brown.opacity(0.86))

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.55))
            }

            Spacer()
        }
    }
}

private struct RewardedGachaTicketButton: View {
    let title: String
    let message: String
    let isEnabled: Bool
    let mode: GachaView.GachaMode
    let action: () -> Void

    private var accent: Color {
        mode == .seed ? .green : .orange
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(isEnabled ? 0.20 : 0.10))
                        .frame(width: 42, height: 42)

                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(isEnabled ? accent.opacity(0.92) : .gray.opacity(0.72))

                    Image(systemName: "ticket.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.yellow.opacity(isEnabled ? 0.95 : 0.62))
                        .offset(x: 13, y: -12)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(isEnabled ? .brown.opacity(0.86) : .gray.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(message)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isEnabled ? .brown.opacity(0.55) : .gray.opacity(0.72))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isEnabled ? "chevron.right.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isEnabled ? accent.opacity(0.78) : .gray.opacity(0.68))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(isEnabled ? 0.82 : 0.62),
                        accent.opacity(isEnabled ? 0.14 : 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(isEnabled ? 0.76 : 0.44), lineWidth: 1)
            )
            .shadow(color: accent.opacity(isEnabled ? 0.13 : 0.04), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct GachaAdLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.20)
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
            .background(.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: .brown.opacity(0.16), radius: 18, y: 10)
        }
    }
}

private struct RewardedGachaTicketCelebrationOverlay: View {
    let id: Int
    let ticketCountText: String
    let mode: GachaView.GachaMode
    let onDismiss: () -> Void

    @State private var isPresented = false
    @State private var ticketLift = false
    @State private var haloPulse = false
    @State private var ribbonSweep = false

    private var accent: Color {
        mode == .seed ? .green : .orange
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            ForEach(0..<34, id: \.self) { index in
                RewardedTicketParticle(index: index, accent: accent, isActive: isPresented)
            }

            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(haloPulse ? 0.62 : 0.34),
                                    accent.opacity(haloPulse ? 0.26 : 0.12),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 138
                            )
                        )
                        .frame(width: 248, height: 248)
                        .scaleEffect(haloPulse ? 1.08 : 0.92)

                    RewardedTicketRibbon(accent: accent, isActive: ribbonSweep)
                        .frame(width: 210, height: 112)

                    RewardedTicketCard(
                        accent: accent,
                        rotation: 0,
                        yOffset: -4,
                        isPrimary: true
                    )
                    .offset(y: ticketLift ? -10 : 16)
                    .scaleEffect(ticketLift ? 1 : 0.86)
                }
                .frame(height: 178)

                VStack(spacing: 6) {
                    Text("広告チケット獲得")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.brown.opacity(0.90))

                    Text("+1枚")
                        .font(.system(size: 23, weight: .black).monospacedDigit())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, accent.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("所持 \(ticketCountText)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.brown.opacity(0.58))
                }

                Text("\(mode.rawValue)でも鉢箱でも使えるチケットです")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.brown.opacity(0.54))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button {
                    dismiss()
                } label: {
                    Text("受け取る")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accent.opacity(0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: 304)
            .background(.white.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.76), lineWidth: 1)
            )
            .shadow(color: .brown.opacity(0.18), radius: 30, y: 16)
            .scaleEffect(isPresented ? 1 : 0.84)
            .opacity(isPresented ? 1 : 0)
        }
        .onAppear {
            isPresented = false
            ticketLift = false
            haloPulse = false
            ribbonSweep = false

            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                isPresented = true
            }
            withAnimation(.interpolatingSpring(stiffness: 92, damping: 9).delay(0.06)) {
                ticketLift = true
            }
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                haloPulse = true
            }
            withAnimation(.easeOut(duration: 0.64).delay(0.12)) {
                ribbonSweep = true
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

private struct RewardedTicketCard: View {
    let accent: Color
    let rotation: Int
    let yOffset: Int
    let isPrimary: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white,
                            Color.yellow.opacity(isPrimary ? 0.38 : 0.24),
                            accent.opacity(isPrimary ? 0.22 : 0.13)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isPrimary ? 92 : 72, height: isPrimary ? 104 : 86)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(.white.opacity(0.86), lineWidth: 1.4)
                )

            VStack(spacing: 8) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: isPrimary ? 34 : 25, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, accent.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("+1")
                    .font(.system(size: isPrimary ? 17 : 13, weight: .black).monospacedDigit())
                    .foregroundStyle(.brown.opacity(0.78))
            }
        }
        .rotationEffect(.degrees(Double(rotation)))
        .offset(y: CGFloat(yOffset))
        .shadow(color: accent.opacity(isPrimary ? 0.22 : 0.12), radius: isPrimary ? 18 : 10, y: 7)
    }
}

private struct RewardedTicketRibbon: View {
    let accent: Color
    let isActive: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.yellow.opacity(0.30),
                            accent.opacity(0.28),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 210, height: 30)
                .rotationEffect(.degrees(-13))
                .offset(x: isActive ? 0 : -130)
                .opacity(isActive ? 1 : 0)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.52), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 150, height: 14)
                .rotationEffect(.degrees(14))
                .offset(x: isActive ? 16 : -120, y: 24)
                .opacity(isActive ? 1 : 0)
        }
    }
}

private struct RewardedTicketParticle: View {
    let index: Int
    let accent: Color
    let isActive: Bool

    private var angle: Double {
        Double(index) / 34 * .pi * 2
    }

    private var distance: Double {
        126 + Double((index * 17) % 54)
    }

    var body: some View {
        Group {
            if index.isMultiple(of: 5) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: CGFloat(8 + index % 5), weight: .black))
                    .foregroundStyle(Color.yellow.opacity(0.86))
            } else if index.isMultiple(of: 3) {
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(8 + index % 6), weight: .black))
                    .foregroundStyle(.white.opacity(0.88))
            } else {
                Circle()
                    .fill((index.isMultiple(of: 2) ? accent : Color.yellow).opacity(0.74))
                    .frame(width: CGFloat(5 + index % 4), height: CGFloat(5 + index % 4))
            }
        }
        .offset(
            x: cos(angle) * (isActive ? distance : 28),
            y: sin(angle) * (isActive ? distance * 0.92 : 24)
        )
        .rotationEffect(.degrees(isActive ? Double(index * 41) : 0))
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.72, dampingFraction: 0.76).delay(Double(index) * 0.018), value: isActive)
    }
}

private struct GachaPrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(color.opacity(configuration.isPressed ? 0.62 : 0.86))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GachaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.brown.opacity(0.68))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(.white.opacity(configuration.isPressed ? 0.42 : 0.62))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
