import SwiftUI

struct WateringEffectView: View {
    let trigger: Int
    let imageHeight: CGFloat

    @State private var isVisible = false
    @State private var isPouring = false
    @State private var isWaterFalling = false

    var body: some View {
        ZStack {
            if isVisible {
                wateringCan
                waterDrops
                soilSplash
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else {
                return
            }

            playAnimation()
        }
    }

    private var wateringCan: some View {
        wateringCanGraphic
            .frame(width: imageHeight * 0.22, height: imageHeight * 0.16)
            .shadow(color: .blue.opacity(0.18), radius: 8, y: 4)
            .rotationEffect(.degrees(isPouring ? 30 : -8), anchor: .center)
            .scaleEffect(isPouring ? 1.04 : 0.96)
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: -imageHeight * 0.24,
                y: -imageHeight * 0.24
            )
            .animation(.spring(response: 0.34, dampingFraction: 0.72), value: isPouring)
    }

    private var wateringCanGraphic: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                RoundedRectangle(cornerRadius: height * 0.24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.96),
                                Color.blue.opacity(0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width * 0.58, height: height * 0.66)
                    .offset(x: -width * 0.08, y: height * 0.08)

                RoundedRectangle(cornerRadius: height * 0.10, style: .continuous)
                    .fill(Color.cyan.opacity(0.88))
                    .frame(width: width * 0.34, height: height * 0.15)
                    .rotationEffect(.degrees(-18))
                    .offset(x: width * 0.28, y: -height * 0.02)

                Circle()
                    .trim(from: 0.16, to: 0.84)
                    .stroke(Color.blue.opacity(0.78), lineWidth: max(width * 0.055, 3))
                    .frame(width: width * 0.42, height: height * 0.70)
                    .rotationEffect(.degrees(12))
                    .offset(x: -width * 0.33, y: height * 0.03)

                Capsule()
                    .fill(Color.cyan.opacity(0.95))
                    .frame(width: width * 0.24, height: height * 0.11)
                    .offset(x: -width * 0.06, y: -height * 0.33)

                Circle()
                    .fill(Color.white.opacity(0.42))
                    .frame(width: width * 0.13, height: width * 0.13)
                    .offset(x: -width * 0.20, y: -height * 0.07)
            }
        }
    }

    private var waterDrops: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                let size = imageHeight * CGFloat(0.018 + randomValue(index: index, salt: 5) * 0.012)
                let startX = -imageHeight * CGFloat(0.12 + randomValue(index: index, salt: 11) * 0.10)
                let endX = -imageHeight * CGFloat(0.02 + randomValue(index: index, salt: 17) * 0.10)
                let startY = -imageHeight * CGFloat(0.16 + randomValue(index: index, salt: 23) * 0.07)
                let endY = imageHeight * CGFloat(0.13 + randomValue(index: index, salt: 31) * 0.12)

                Capsule()
                    .fill(Color.cyan.opacity(0.62))
                    .frame(width: size * 0.64, height: size * 1.55)
                    .rotationEffect(.degrees(24))
                    .opacity(isWaterFalling ? 0.85 : 0.0)
                    .offset(
                        x: isWaterFalling ? endX : startX,
                        y: isWaterFalling ? endY : startY
                    )
                    .animation(
                        .easeIn(duration: 0.62)
                        .delay(0.02 + Double(index) * 0.035),
                        value: isWaterFalling
                    )
            }
        }
    }

    private var soilSplash: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.cyan.opacity(isWaterFalling ? 0.22 : 0.0))
                    .frame(
                        width: imageHeight * CGFloat(0.018 + randomValue(index: index, salt: 41) * 0.018),
                        height: imageHeight * CGFloat(0.018 + randomValue(index: index, salt: 41) * 0.018)
                    )
                    .scaleEffect(isWaterFalling ? 1.8 : 0.4)
                    .offset(
                        x: imageHeight * CGFloat(-0.10 + randomValue(index: index, salt: 47) * 0.20),
                        y: imageHeight * CGFloat(0.18 + randomValue(index: index, salt: 53) * 0.06)
                    )
                    .animation(
                        .easeOut(duration: 0.44)
                        .delay(0.34 + Double(index) * 0.04),
                        value: isWaterFalling
                    )
            }
        }
    }

    private func playAnimation() {
        isPouring = false
        isWaterFalling = false
        isVisible = true

        // 先にジョウロを下向きに傾けてから水を出します。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            isPouring = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            isWaterFalling = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeOut(duration: 0.20)) {
                isVisible = false
            }
        }
    }

    private func randomValue(index: Int, salt: Int) -> Double {
        let value = sin(Double(index * 131 + salt * 307)) * 43758.5453
        return value - floor(value)
    }
}

#Preview("Watering Effect") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.98, blue: 0.92),
                Color(red: 0.88, green: 0.97, blue: 0.92)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        WateringEffectView(trigger: 1, imageHeight: 360)
    }
}
