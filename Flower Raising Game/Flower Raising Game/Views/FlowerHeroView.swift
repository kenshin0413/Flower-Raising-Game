import SwiftUI

struct FlowerHeroView: View {
    let flower: FlowerState
    let plantImageName: String?
    let vaseStyle: VaseStyle
    let growthPercentText: String
    let imageHeight: CGFloat
    let windSpeed: Double?
    let onTap: () -> Void

    @State private var isFlowerMoving = false
    @State private var tapPulse = false

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

            Image(vaseStyle.imageName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: imageHeight * CGFloat(vaseStyle.frameWidthRatio),
                    height: imageHeight * CGFloat(vaseStyle.frameHeightRatio)
                )
                .offset(y: imageHeight * CGFloat(vaseStyle.verticalOffsetRatio))

            if let plantImageName {
                Image(plantImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageHeight * 0.80 * plantScale, height: imageHeight * 0.80 * plantScale)
                    .scaleEffect(tapPulse ? 1.045 : 1.0, anchor: .bottom)
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
        .contentShape(Rectangle())
        .onTapGesture {
            guard plantImageName != nil else {
                return
            }

            onTap()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.42)) {
                tapPulse = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.70)) {
                    tapPulse = false
                }
            }
        }
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
              imageName != "ChatGPT Image 2026年5月15日 12_33_35",
              !isStaticSeedImage(imageName) else {
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
        case "ChatGPT Image 2026年6月2日 16_20_33 (1)":
            return (-0.003, 0.312)
        case "ChatGPT Image 2026年6月2日 16_57_23 (1)":
            return (-0.003, 0.306)
        case "ChatGPT Image 2026年6月2日 16_20_33 (2)":
            return (-0.003, 0.316)
        case "ChatGPT Image 2026年6月2日 16_26_16 (1)",
            "ChatGPT Image 2026年6月2日 16_47_12 (1)":
            return (-0.003, 0.326)
        case "ChatGPT Image 2026年6月2日 16_57_23 (2)":
            return (-0.003, 0.334)
        case "ChatGPT Image 2026年6月2日 16_20_33 (3)":
            return (-0.010, 0.255)
        case "ChatGPT Image 2026年6月2日 16_26_16 (2)",
            "ChatGPT Image 2026年6月2日 16_47_12 (2)":
            return (-0.010, 0.280)
        case "ChatGPT Image 2026年6月2日 16_57_24 (3)":
            return (-0.002, 0.282)
        case "ChatGPT Image 2026年6月2日 16_20_33 (4)":
            return (-0.002, 0.217)
        case "ChatGPT Image 2026年6月2日 16_26_17 (3)":
            return (0.006, 0.222)
        case "ChatGPT Image 2026年6月2日 16_47_13 (3)":
            return (0.006, 0.197)
        case "ChatGPT Image 2026年6月2日 16_57_25 (4)":
            return (-0.002, 0.218)
        case "ChatGPT Image 2026年6月2日 16_20_34 (5)":
            return (-0.002, 0.147)
        case "ChatGPT Image 2026年6月2日 16_26_17 (4)",
            "ChatGPT Image 2026年6月2日 16_47_13 (4)":
            return (-0.002, 0.152)
        case "ChatGPT Image 2026年6月2日 16_57_25 (5)":
            return (-0.002, 0.145)
        case "ChatGPT Image 2026年6月2日 16_57_26 (6)":
            return (0.013, 0.116)
        case "ChatGPT Image 2026年6月2日 17_07_39 (2)",
            "ChatGPT Image 2026年6月2日 17_12_08 (2)":
            return (-0.002, 0.218)
        case "ChatGPT Image 2026年6月2日 17_07_39 (3)",
            "ChatGPT Image 2026年6月2日 17_12_08 (3)",
            "ChatGPT Image 2026年6月2日 17_07_40 (4)",
            "ChatGPT Image 2026年6月2日 17_12_08 (4)":
            return (-0.002, 0.130)
        case "ChatGPT Image 2026年6月2日 16_57_26 (7)",
            "ChatGPT Image 2026年6月2日 16_57_27 (8)",
            "ChatGPT Image 2026年6月2日 17_07_39 (1)",
            "ChatGPT Image 2026年6月2日 17_07_40 (5)",
            "ChatGPT Image 2026年6月2日 17_07_41 (6)",
            "ChatGPT Image 2026年6月2日 17_07_41 (7)",
            "ChatGPT Image 2026年6月2日 17_07_42 (8)",
            "ChatGPT Image 2026年6月2日 17_12_08 (1)",
            "ChatGPT Image 2026年6月2日 17_12_09 (5)",
            "ChatGPT Image 2026年6月2日 17_12_09 (6)",
            "ChatGPT Image 2026年6月2日 17_12_10 (7)",
            "ChatGPT Image 2026年6月2日 17_12_10 (8)":
            return (-0.002, 0.116)
        case "ChatGPT Image 2026年6月2日 17_07_43 (9)",
            "ChatGPT Image 2026年6月2日 17_12_11 (9)":
            return (0.030, 0.116)
        case "ChatGPT Image 2026年6月2日 16_57_27 (9)":
            return (-0.010, 0.116)
        case "ChatGPT Image 2026年6月2日 16_57_28 (10)":
            return (0.025, 0.116)
        case "ChatGPT Image 2026年6月13日 01_08_04":
            return (0.000, 0.318)
        case "ChatGPT Image 2026年6月13日 01_46_14":
            return (0.000, 0.092)
        case "ChatGPT Image 2026年6月13日 00_58_38 (3)":
            return (0.000, 0.297)
        case "ChatGPT Image 2026年7月1日 17_03_05 (1)":
            return (0.002, 0.299)
        case "ChatGPT Image 2026年7月1日 17_12_44":
            return (-0.001, 0.299)
        case "ChatGPT Image 2026年6月13日 00_58_38 (4)":
            return (0.000, 0.125)
        case "ChatGPT Image 2026年7月1日 17_03_05 (2)":
            return (-0.009, 0.128)
        case "ChatGPT Image 2026年7月1日 17_12_40":
            return (-0.005, 0.123)
        case "ChatGPT Image 2026年6月13日 00_58_38 (5)":
            return (0.000, 0.132)
        case "ChatGPT Image 2026年7月1日 17_03_05 (3)":
            return (0.000, 0.132)
        case "ChatGPT Image 2026年7月1日 17_12_35":
            return (-0.010, 0.131)
        case "ChatGPT Image 2026年6月13日 00_58_39 (6)",
            "ChatGPT Image 2026年6月13日 00_58_39 (7)":
            return (0.000, 0.034)
        case "ChatGPT Image 2026年7月1日 17_03_05 (4)":
            return (-0.006, 0.037)
        case "ChatGPT Image 2026年7月1日 17_03_06 (5)":
            return (0.014, 0.039)
        case "ChatGPT Image 2026年7月1日 17_12_31":
            return (-0.008, 0.033)
        case "ChatGPT Image 2026年7月1日 17_12_26":
            return (0.005, 0.036)
        case "ChatGPT Image 2026年6月13日 00_58_39 (8)",
            "ChatGPT Image 2026年6月13日 00_58_39 (9)",
            "ChatGPT Image 2026年6月13日 00_58_40 (10)":
            return (-0.030, 0.034)
        case "ChatGPT Image 2026年7月1日 17_03_06 (6)":
            return (-0.032, 0.052)
        case "ChatGPT Image 2026年7月1日 17_03_06 (7)":
            return (-0.023, 0.058)
        case "ChatGPT Image 2026年7月1日 17_03_06 (8)":
            return (-0.002, 0.042)
        case "ChatGPT Image 2026年7月1日 17_11_54 (7)":
            return (-0.028, 0.033)
        case "ChatGPT Image 2026年7月1日 17_11_54 (8)":
            return (-0.024, 0.033)
        case "ChatGPT Image 2026年7月1日 17_12_22":
            return (-0.035, 0.040)
        case "ChatGPT Image 2026年6月13日 02_56_42 (1)":
            return (0.000, 0.194)
        case "ChatGPT Image 2026年6月13日 02_56_42 (2)":
            return (0.000, 0.190)
        case "ChatGPT Image 2026年7月1日 18_05_23 (1)":
            return (0.000, 0.194)
        case "ChatGPT Image 2026年7月1日 18_09_12 (1)":
            return (0.000, 0.200)
        case "ChatGPT Image 2026年7月1日 18_05_23 (2)":
            return (0.000, 0.199)
        case "ChatGPT Image 2026年7月1日 18_09_12 (2)":
            return (-0.003, 0.220)
        case "ChatGPT Image 2026年6月13日 02_56_43 (5)":
            return (0.004, 0.149)
        case "ChatGPT Image 2026年7月1日 18_05_23 (3)":
            return (0.004, 0.153)
        case "ChatGPT Image 2026年7月1日 18_09_13 (3)":
            return (0.005, 0.150)
        case "ChatGPT Image 2026年6月13日 02_56_43 (4)":
            return (0.020, 0.175)
        case "ChatGPT Image 2026年7月1日 18_05_24 (4)":
            return (0.020, 0.169)
        case "ChatGPT Image 2026年7月1日 18_09_13 (4)":
            return (0.020, 0.175)
        case "ChatGPT Image 2026年6月13日 02_56_43 (3)":
            return (0.000, 0.184)
        case "ChatGPT Image 2026年7月1日 18_05_24 (5)":
            return (0.002, 0.209)
        case "ChatGPT Image 2026年7月1日 18_09_14 (5)":
            return (0.000, 0.184)
        case "ChatGPT Image 2026年6月13日 02_56_43 (6)":
            return (0.000, 0.117)
        case "ChatGPT Image 2026年7月1日 18_05_24 (6)":
            return (0.002, 0.130)
        case "ChatGPT Image 2026年7月1日 18_09_14 (6)":
            return (0.000, 0.117)
        case "ChatGPT Image 2026年6月13日 02_56_44 (8)":
            return (0.000, 0.126)
        case "ChatGPT Image 2026年7月1日 18_05_25 (7)":
            return (-0.001, 0.105)
        case "ChatGPT Image 2026年7月1日 18_09_14 (7)":
            return (-0.002, 0.106)
        case "ChatGPT Image 2026年6月13日 02_56_44 (7)":
            return (0.000, 0.113)
        case "ChatGPT Image 2026年7月1日 18_05_25 (8)":
            return (0.000, 0.130)
        case "ChatGPT Image 2026年7月1日 18_09_15 (8)":
            return (0.002, 0.133)
        case "ChatGPT Image 2026年6月13日 02_56_44 (9)":
            return (0.006, 0.123)
        case "ChatGPT Image 2026年7月1日 18_05_26 (9)":
            return (0.008, 0.123)
        case "ChatGPT Image 2026年7月1日 18_09_15 (9)":
            return (0.006, 0.123)
        case "ChatGPT Image 2026年6月13日 02_56_44 (10)":
            return (-0.005, 0.105)
        case "ChatGPT Image 2026年7月1日 18_05_26 (10)":
            return (-0.005, 0.103)
        case "ChatGPT Image 2026年7月1日 18_09_16 (10)":
            return (-0.005, 0.105)
        case "ChatGPT Image 2026年6月13日 14_08_22 (1)":
            return (0.000, 0.315)
        case "ChatGPT Image 2026年6月13日 14_09_32",
            "ChatGPT Image 2026年6月13日 14_09_38",
            "ChatGPT Image 2026年7月1日 18_23_39",
            "ChatGPT Image 2026年7月1日 18_20_29 (10)",
            "ChatGPT Image 2026年7月1日 18_28_48 (10)":
            return (0.000, 0.180)
        case "ChatGPT Image 2026年7月1日 18_28_48 (9)":
            return (0.000, 0.180)
        case "ChatGPT Image 2026年7月1日 18_20_25 (2)",
            "ChatGPT Image 2026年7月1日 18_28_43 (2)":
            return (0.000, 0.315)
        case "ChatGPT Image 2026年6月13日 14_08_22 (4)":
            return (0.000, 0.174)
        case "ChatGPT Image 2026年7月1日 18_20_26 (3)",
            "ChatGPT Image 2026年7月1日 18_28_44 (3)":
            return (0.000, 0.180)
        case "ChatGPT Image 2026年6月13日 14_08_22 (5)":
            return (0.000, 0.142)
        case "ChatGPT Image 2026年7月1日 18_20_26 (4)",
            "ChatGPT Image 2026年7月1日 18_28_44 (4)":
            return (0.000, 0.142)
        case "ChatGPT Image 2026年6月13日 14_08_23 (6)",
            "ChatGPT Image 2026年6月13日 14_08_23 (7)",
            "ChatGPT Image 2026年6月13日 14_08_11 (8)",
            "ChatGPT Image 2026年6月13日 14_08_24 (9)":
            return (0.000, 0.126)
        case "ChatGPT Image 2026年7月1日 18_20_27 (5)",
            "ChatGPT Image 2026年7月1日 18_20_27 (6)",
            "ChatGPT Image 2026年7月1日 18_20_28 (7)",
            "ChatGPT Image 2026年7月1日 18_23_34",
            "ChatGPT Image 2026年7月1日 18_20_25 (1)",
            "ChatGPT Image 2026年7月1日 18_28_46 (5)",
            "ChatGPT Image 2026年7月1日 18_28_46 (6)",
            "ChatGPT Image 2026年7月1日 18_28_43 (1)":
            return (0.000, 0.132)
        case "ChatGPT Image 2026年7月1日 18_28_47 (7)":
            return (0.000, 0.120)
        case "ChatGPT Image 2026年7月1日 18_28_47 (8)":
            return (0.000, 0.120)
        case "ChatGPT Image 2026年6月13日 14_08_24 (10)":
            return (0.000, 0.138)
        case "ChatGPT Image 2026年6月2日 16_20_34 (6)":
            return (-0.018, 0.110)
        case "ChatGPT Image 2026年6月2日 16_20_34 (7)":
            return (0.030, 0.092)
        case "ChatGPT Image 2026年6月2日 16_20_35 (10)":
            return (-0.002, 0.102)
        case "ChatGPT Image 2026年6月2日 16_20_35 (8)",
            "ChatGPT Image 2026年6月2日 16_20_35 (9)",
            "ChatGPT Image 2026年6月2日 16_26_18 (7)",
            "ChatGPT Image 2026年6月2日 16_26_19 (8)",
            "ChatGPT Image 2026年6月2日 16_47_15 (7)",
            "ChatGPT Image 2026年6月2日 16_47_16 (8)":
            return (-0.002, 0.110)
        case "ChatGPT Image 2026年6月2日 16_26_17 (5)",
            "ChatGPT Image 2026年6月2日 16_47_14 (5)":
            return (-0.010, 0.125)
        case "ChatGPT Image 2026年6月2日 16_26_18 (6)",
            "ChatGPT Image 2026年6月2日 16_47_14 (6)":
            return (-0.002, 0.095)
        case "ChatGPT Image 2026年6月2日 16_26_19 (9)":
            return (0.010, 0.110)
        case "ChatGPT Image 2026年6月2日 16_47_17 (9)":
            return (0.010, 0.100)
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
        case "ChatGPT Image 2026年6月2日 16_20_33 (1)":
            return 0.145
        case "ChatGPT Image 2026年6月2日 16_57_23 (1)":
            return 0.145
        case "ChatGPT Image 2026年6月2日 16_26_16 (1)":
            return 0.20
        case "ChatGPT Image 2026年6月2日 16_20_33 (2)",
            "ChatGPT Image 2026年6月2日 16_47_12 (1)",
            "ChatGPT Image 2026年6月2日 16_57_23 (2)":
            return 0.22
        case "ChatGPT Image 2026年6月2日 16_20_33 (3)",
            "ChatGPT Image 2026年6月2日 16_26_16 (2)",
            "ChatGPT Image 2026年6月2日 16_47_12 (2)",
            "ChatGPT Image 2026年6月2日 16_57_24 (3)":
            return 0.36
        case "ChatGPT Image 2026年6月2日 16_20_33 (4)",
            "ChatGPT Image 2026年6月2日 16_26_17 (3)",
            "ChatGPT Image 2026年6月2日 16_47_13 (3)",
            "ChatGPT Image 2026年6月2日 16_57_25 (4)":
            return 0.48
        case "ChatGPT Image 2026年6月2日 16_20_34 (5)",
            "ChatGPT Image 2026年6月2日 16_26_17 (4)",
            "ChatGPT Image 2026年6月2日 16_47_13 (4)",
            "ChatGPT Image 2026年6月2日 16_57_25 (5)":
            return 0.58
        case "ChatGPT Image 2026年6月13日 01_08_04":
            return 1.13
        case "ChatGPT Image 2026年6月13日 01_46_14":
            return 0.85
        case "ChatGPT Image 2026年6月13日 00_58_38 (3)",
            "ChatGPT Image 2026年7月1日 17_03_05 (1)",
            "ChatGPT Image 2026年7月1日 17_12_44":
            return 0.50
        case "ChatGPT Image 2026年6月13日 00_58_38 (4)",
            "ChatGPT Image 2026年6月13日 00_58_38 (5)",
            "ChatGPT Image 2026年7月1日 17_03_05 (2)",
            "ChatGPT Image 2026年7月1日 17_03_05 (3)",
            "ChatGPT Image 2026年7月1日 17_12_40",
            "ChatGPT Image 2026年7月1日 17_12_35":
            return 0.70
        case "ChatGPT Image 2026年6月13日 00_58_39 (6)",
            "ChatGPT Image 2026年6月13日 00_58_39 (7)",
            "ChatGPT Image 2026年6月13日 00_58_39 (8)",
            "ChatGPT Image 2026年6月13日 00_58_39 (9)",
            "ChatGPT Image 2026年6月13日 00_58_40 (10)",
            "ChatGPT Image 2026年7月1日 17_03_05 (4)",
            "ChatGPT Image 2026年7月1日 17_03_06 (5)",
            "ChatGPT Image 2026年7月1日 17_03_06 (6)",
            "ChatGPT Image 2026年7月1日 17_03_06 (7)",
            "ChatGPT Image 2026年7月1日 17_03_06 (8)",
            "ChatGPT Image 2026年7月1日 17_11_54 (7)",
            "ChatGPT Image 2026年7月1日 17_11_54 (8)",
            "ChatGPT Image 2026年7月1日 17_12_22",
            "ChatGPT Image 2026年7月1日 17_12_26",
            "ChatGPT Image 2026年7月1日 17_12_31":
            return 0.82
        case "ChatGPT Image 2026年6月13日 02_56_42 (1)",
            "ChatGPT Image 2026年7月1日 18_05_23 (1)",
            "ChatGPT Image 2026年7月1日 18_09_12 (1)",
            "ChatGPT Image 2026年6月13日 02_56_42 (2)",
            "ChatGPT Image 2026年7月1日 18_05_23 (2)",
            "ChatGPT Image 2026年7月1日 18_09_12 (2)":
            return 0.45
        case "ChatGPT Image 2026年6月13日 02_56_43 (4)",
            "ChatGPT Image 2026年6月13日 02_56_43 (5)",
            "ChatGPT Image 2026年7月1日 18_05_23 (3)",
            "ChatGPT Image 2026年7月1日 18_09_13 (3)",
            "ChatGPT Image 2026年7月1日 18_05_24 (4)",
            "ChatGPT Image 2026年7月1日 18_09_13 (4)":
            return 0.58
        case "ChatGPT Image 2026年6月13日 02_56_43 (3)",
            "ChatGPT Image 2026年7月1日 18_05_24 (5)",
            "ChatGPT Image 2026年7月1日 18_09_14 (5)":
            return 0.48
        case "ChatGPT Image 2026年6月13日 02_56_43 (6)",
            "ChatGPT Image 2026年7月1日 18_05_24 (6)",
            "ChatGPT Image 2026年7月1日 18_09_14 (6)":
            return 0.64
        case "ChatGPT Image 2026年6月13日 02_56_44 (8)",
            "ChatGPT Image 2026年7月1日 18_05_25 (7)",
            "ChatGPT Image 2026年7月1日 18_09_14 (7)":
            return 0.70
        case "ChatGPT Image 2026年6月13日 02_56_44 (7)",
            "ChatGPT Image 2026年7月1日 18_05_25 (8)",
            "ChatGPT Image 2026年7月1日 18_09_15 (8)":
            return 0.68
        case "ChatGPT Image 2026年6月13日 02_56_44 (9)",
            "ChatGPT Image 2026年7月1日 18_05_26 (9)",
            "ChatGPT Image 2026年7月1日 18_09_15 (9)":
            return 0.62
        case "ChatGPT Image 2026年6月13日 02_56_44 (10)",
            "ChatGPT Image 2026年7月1日 18_05_26 (10)",
            "ChatGPT Image 2026年7月1日 18_09_16 (10)":
            return 0.64
        case "ChatGPT Image 2026年7月1日 18_09_15 (9)":
            return 0.62
        case "ChatGPT Image 2026年6月13日 14_08_22 (1)":
            return 0.22
        case "ChatGPT Image 2026年6月13日 14_09_32",
            "ChatGPT Image 2026年6月13日 14_09_38",
            "ChatGPT Image 2026年7月1日 18_23_39",
            "ChatGPT Image 2026年7月1日 18_20_29 (10)",
            "ChatGPT Image 2026年7月1日 18_28_48 (9)",
            "ChatGPT Image 2026年7月1日 18_28_48 (10)":
            return 0.50
        case "ChatGPT Image 2026年7月1日 18_20_25 (2)",
            "ChatGPT Image 2026年7月1日 18_28_43 (2)":
            return 0.22
        case "ChatGPT Image 2026年6月13日 14_08_22 (4)":
            return 0.52
        case "ChatGPT Image 2026年7月1日 18_20_26 (3)",
            "ChatGPT Image 2026年7月1日 18_28_44 (3)":
            return 0.52
        case "ChatGPT Image 2026年6月13日 14_08_22 (5)":
            return 0.58
        case "ChatGPT Image 2026年7月1日 18_20_26 (4)",
            "ChatGPT Image 2026年7月1日 18_28_44 (4)":
            return 0.58
        case "ChatGPT Image 2026年6月13日 14_08_23 (6)",
            "ChatGPT Image 2026年6月13日 14_08_23 (7)",
            "ChatGPT Image 2026年6月13日 14_08_11 (8)",
            "ChatGPT Image 2026年6月13日 14_08_24 (9)":
            return 0.62
        case "ChatGPT Image 2026年7月1日 18_20_27 (5)",
            "ChatGPT Image 2026年7月1日 18_20_27 (6)",
            "ChatGPT Image 2026年7月1日 18_20_28 (7)",
            "ChatGPT Image 2026年7月1日 18_23_34",
            "ChatGPT Image 2026年7月1日 18_20_25 (1)",
            "ChatGPT Image 2026年7月1日 18_28_46 (5)",
            "ChatGPT Image 2026年7月1日 18_28_46 (6)",
            "ChatGPT Image 2026年7月1日 18_28_47 (7)",
            "ChatGPT Image 2026年7月1日 18_28_47 (8)",
            "ChatGPT Image 2026年7月1日 18_28_43 (1)":
            return 0.62
        case "ChatGPT Image 2026年6月13日 14_08_24 (10)":
            return 0.58
        case "ChatGPT Image 2026年6月2日 16_57_26 (6)",
            "ChatGPT Image 2026年6月2日 16_57_26 (7)",
            "ChatGPT Image 2026年6月2日 16_57_27 (8)",
            "ChatGPT Image 2026年6月2日 16_57_27 (9)",
            "ChatGPT Image 2026年6月2日 16_57_28 (10)",
            "ChatGPT Image 2026年6月2日 17_07_39 (1)",
            "ChatGPT Image 2026年6月2日 17_07_39 (2)",
            "ChatGPT Image 2026年6月2日 17_07_39 (3)",
            "ChatGPT Image 2026年6月2日 17_07_40 (4)",
            "ChatGPT Image 2026年6月2日 17_07_40 (5)",
            "ChatGPT Image 2026年6月2日 17_07_41 (6)",
            "ChatGPT Image 2026年6月2日 17_07_41 (7)",
            "ChatGPT Image 2026年6月2日 17_07_42 (8)",
            "ChatGPT Image 2026年6月2日 17_07_43 (9)",
            "ChatGPT Image 2026年6月2日 17_12_08 (1)",
            "ChatGPT Image 2026年6月2日 17_12_08 (2)",
            "ChatGPT Image 2026年6月2日 17_12_08 (3)",
            "ChatGPT Image 2026年6月2日 17_12_08 (4)",
            "ChatGPT Image 2026年6月2日 17_12_09 (5)",
            "ChatGPT Image 2026年6月2日 17_12_09 (6)",
            "ChatGPT Image 2026年6月2日 17_12_10 (7)",
            "ChatGPT Image 2026年6月2日 17_12_10 (8)",
            "ChatGPT Image 2026年6月2日 17_12_11 (9)":
            return 0.62
        case "ChatGPT Image 2026年6月2日 16_20_34 (6)",
            "ChatGPT Image 2026年6月2日 16_20_34 (7)",
            "ChatGPT Image 2026年6月2日 16_20_35 (8)",
            "ChatGPT Image 2026年6月2日 16_20_35 (9)",
            "ChatGPT Image 2026年6月2日 16_20_35 (10)",
            "ChatGPT Image 2026年6月2日 16_26_17 (5)",
            "ChatGPT Image 2026年6月2日 16_26_18 (6)",
            "ChatGPT Image 2026年6月2日 16_26_18 (7)",
            "ChatGPT Image 2026年6月2日 16_26_19 (8)",
            "ChatGPT Image 2026年6月2日 16_26_19 (9)",
            "ChatGPT Image 2026年6月2日 16_47_14 (5)",
            "ChatGPT Image 2026年6月2日 16_47_14 (6)",
            "ChatGPT Image 2026年6月2日 16_47_15 (7)",
            "ChatGPT Image 2026年6月2日 16_47_16 (8)",
            "ChatGPT Image 2026年6月2日 16_47_17 (9)":
            return 0.68
        default:
            return 1.0
        }
    }

    private func isStaticSeedImage(_ imageName: String) -> Bool {
        imageName == "ChatGPT Image 2026年6月2日 16_20_33 (1)" ||
            imageName == "ChatGPT Image 2026年6月2日 16_57_23 (1)" ||
            imageName == "ChatGPT Image 2026年6月13日 01_08_04" ||
            imageName == "ChatGPT Image 2026年6月13日 02_56_42 (1)" ||
            imageName == "ChatGPT Image 2026年6月13日 14_08_22 (1)"
    }
}
