import SwiftUI

struct FertilizerEffectView: View {
    let trigger: Int
    let imageHeight: CGFloat

    @State private var isVisible = false
    @State private var isPouring = false

    var body: some View {
        ZStack {
            if isVisible {
                fertilizerBag
                fertilizerPellets
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

    private var fertilizerBag: some View {
        ZStack {
            RoundedRectangle(cornerRadius: imageHeight * 0.018, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.78, green: 0.58, blue: 0.32),
                            Color(red: 0.58, green: 0.40, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: imageHeight * 0.17, height: imageHeight * 0.22)

            RoundedRectangle(cornerRadius: imageHeight * 0.012, style: .continuous)
                .fill(Color.green.opacity(0.72))
                .frame(width: imageHeight * 0.10, height: imageHeight * 0.06)
                .offset(y: -imageHeight * 0.02)

            Image(systemName: "leaf.fill")
                .font(.system(size: imageHeight * 0.045, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))
                .offset(y: -imageHeight * 0.02)
        }
        .rotationEffect(.degrees(isPouring ? 24 : 4), anchor: .bottomTrailing)
        .scaleEffect(isPouring ? 1.02 : 0.96)
        .offset(x: imageHeight * 0.23, y: -imageHeight * 0.20)
        .shadow(color: .brown.opacity(0.20), radius: 8, y: 4)
        .animation(.spring(response: 0.34, dampingFraction: 0.74), value: isPouring)
    }

    private var fertilizerPellets: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                let size = imageHeight * CGFloat(0.014 + randomValue(index: index, salt: 5) * 0.014)
                let startX = imageHeight * CGFloat(0.15 + randomValue(index: index, salt: 11) * 0.12)
                let endX = imageHeight * CGFloat(-0.10 + randomValue(index: index, salt: 17) * 0.22)
                let startY = -imageHeight * CGFloat(0.09 + randomValue(index: index, salt: 23) * 0.09)
                let endY = imageHeight * CGFloat(0.18 + randomValue(index: index, salt: 31) * 0.08)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.52, green: 0.36, blue: 0.16),
                                Color(red: 0.30, green: 0.20, blue: 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .opacity(isPouring ? 0.95 : 0.0)
                    .offset(
                        x: isPouring ? endX : startX,
                        y: isPouring ? endY : startY
                    )
                    .animation(
                        .easeIn(duration: 0.58)
                        .delay(0.10 + Double(index) * 0.025),
                        value: isPouring
                    )
            }
        }
    }

    private func playAnimation() {
        isVisible = true
        isPouring = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            isPouring = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeOut(duration: 0.22)) {
                isVisible = false
            }
        }
    }

    private func randomValue(index: Int, salt: Int) -> Double {
        let value = sin(Double(index * 149 + salt * 337)) * 43758.5453
        return value - floor(value)
    }
}

#Preview("Fertilizer Effect") {
    ZStack {
        Color.green.opacity(0.12).ignoresSafeArea()
        FertilizerEffectView(trigger: 1, imageHeight: 360)
    }
}
