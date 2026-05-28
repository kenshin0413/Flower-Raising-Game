import SwiftUI

struct FlowerHeroView: View {
    let flower: FlowerState
    let plantImageName: String?
    let growthPercentText: String
    let imageHeight: CGFloat
    let windSpeed: Double?

    @State private var isFlowerMoving = false

    var body: some View {
        let plantOffset = plantOffsetCorrection(for: plantImageName)
        let plantScale = plantScaleCorrection(for: plantImageName)
        let sway = swaySettings(windSpeed: windSpeed, imageName: plantImageName)

        ZStack {
            Ellipse()
                .fill(.green.opacity(0.16))
                .frame(width: imageHeight * 0.82, height: imageHeight * 0.42)
                .blur(radius: 28)
                .offset(y: imageHeight * 0.18)

            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: imageHeight * 0.16, height: imageHeight * 0.16)
                .blur(radius: 10)
                .offset(x: -imageHeight * 0.28, y: -imageHeight * 0.16)

            Circle()
                .fill(.yellow.opacity(0.14))
                .frame(width: imageHeight * 0.11, height: imageHeight * 0.11)
                .blur(radius: 9)
                .offset(x: imageHeight * 0.26, y: -imageHeight * 0.08)

            Image("tulip_pot")
                .resizable()
                .scaledToFit()
                .frame(width: imageHeight * 0.60, height: imageHeight * 0.42)
                .offset(y: imageHeight * 0.24)

            if let plantImageName {
                Image(plantImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageHeight * 0.80 * plantScale, height: imageHeight * 0.80 * plantScale)
                    .rotationEffect(.degrees(isFlowerMoving ? sway.angle : -sway.angle), anchor: .bottom)
                    .offset(x: isFlowerMoving ? imageHeight * sway.horizontalOffset : -imageHeight * sway.horizontalOffset)
                    .offset(
                        x: imageHeight * (0.002 + plantOffset.x),
                        y: imageHeight * (-0.190 + plantOffset.y)
                    )
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .padding(.horizontal, 6)
        .offset(y: imageHeight * 0.055)
        .onAppear {
            startSwayAnimation(sway: sway)
        }
        .onChange(of: windSpeed ?? 0) { _, _ in
            isFlowerMoving = false
            DispatchQueue.main.async {
                startSwayAnimation(sway: sway)
            }
        }
    }

    private func startSwayAnimation(sway: (angle: Double, horizontalOffset: CGFloat, duration: Double)) {
        withAnimation(.easeInOut(duration: sway.duration).repeatForever(autoreverses: true)) {
            isFlowerMoving = true
        }
    }

    private func swaySettings(windSpeed: Double?, imageName: String?) -> (angle: Double, horizontalOffset: CGFloat, duration: Double) {
        // 鉢だけの状態や枯れた状態では、風で揺れても不自然なので止めます。
        guard let imageName,
              !imageName.hasPrefix("dead_stage"),
              !imageName.hasPrefix("ChatGPT Image") else {
            return (0, 0, 3.0)
        }

        let speed = windSpeed ?? 0

        switch speed {
        case 35...:
            return (4.8, 0.010, 1.15)
        case 24..<35:
            return (3.5, 0.007, 1.45)
        case 14..<24:
            return (2.2, 0.004, 2.0)
        case 6..<14:
            return (1.2, 0.002, 2.8)
        default:
            return (0.7, 0.001, 3.4)
        }
    }

    private func plantOffsetCorrection(for imageName: String?) -> (x: CGFloat, y: CGFloat) {
        switch imageName {
        case "ChatGPT Image 2026年5月15日 12_33_35":
            return (-0.003, 0.308)
        case "growth_stage_02":
            return (-0.003, 0.012)
        case "growth_stage_03":
            return (0, 0)
        case "growth_stage_04":
            return (-0.002, -0.008)
        case "growth_stage_05":
            return (-0.004, 0.014)
        case "growth_stage_06":
            return (-0.009, -0.014)
        case "growth_stage_07":
            return (-0.007, -0.001)
        case "growth_stage_08":
            return (-0.004, -0.009)
        case "growth_stage_09":
            return (-0.002, -0.008)
        case "growth_stage_10":
            return (-0.018, 0.003)
        case "wilted_stage_02":
            return (0.012, 0.013)
        case "wilted_stage_03":
            return (0, 0)
        case "wilted_stage_04":
            return (-0.003, -0.008)
        case "wilted_stage_05":
            return (-0.002, 0.013)
        case "wilted_stage_06":
            return (-0.003, -0.001)
        case "wilted_stage_07":
            return (0.006, -0.008)
        case "wilted_stage_08":
            return (-0.004, -0.009)
        case "wilted_stage_09":
            return (-0.003, 0.024)
        case "wilted_stage_10":
            return (-0.012, -0.009)
        case "dead_stage_02":
            return (-0.002, 0.018)
        case "dead_stage_03":
            return (-0.002, 0.000)
        case "dead_stage_04":
            return (-0.002, 0.000)
        case "dead_stage_05":
            return (-0.002, 0.012)
        case "dead_stage_06":
            return (-0.008, 0.000)
        case "dead_stage_07":
            return (-0.002, -0.012)
        case "dead_stage_08":
            return (-0.008, -0.006)
        case "dead_stage_09":
            return (-0.008, -0.006)
        case "dead_stage_10":
            return (-0.014, -0.006)
        default:
            return (0, 0)
        }
    }

    private func plantScaleCorrection(for imageName: String?) -> CGFloat {
        switch imageName {
        case "ChatGPT Image 2026年5月15日 12_33_35":
            return 0.145
        default:
            return 1.0
        }
    }
}
