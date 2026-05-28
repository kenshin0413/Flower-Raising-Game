import SwiftUI

struct LightEffectView: View {
    let trigger: Int
    let imageHeight: CGFloat

    @State private var isVisible = false
    @State private var isShining = false
    @State private var isAiming = false

    var body: some View {
        ZStack {
            if isVisible {
                flashlightBeam
                plantLightSpot
                flashlightBody
                dustParticles
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

    private var flashlightBeam: some View {
        FlashlightBeamShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(isShining ? 0.58 : 0.0),
                        Color.yellow.opacity(isShining ? 0.22 : 0.0),
                        Color.orange.opacity(isShining ? 0.08 : 0.0),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
            .frame(width: imageHeight * 0.82, height: imageHeight * 0.58)
            .blur(radius: imageHeight * 0.018)
            .scaleEffect(isShining ? 1.0 : 0.72, anchor: .topTrailing)
            .offset(x: imageHeight * 0.10, y: -imageHeight * 0.24)
            .animation(.easeOut(duration: 0.28), value: isShining)
    }

    private var plantLightSpot: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(isShining ? 0.45 : 0.0),
                        Color.yellow.opacity(isShining ? 0.26 : 0.0),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: imageHeight * 0.22
                )
            )
            .frame(width: imageHeight * 0.56, height: imageHeight * 0.30)
            .blur(radius: imageHeight * 0.01)
            .offset(x: -imageHeight * 0.02, y: -imageHeight * 0.08)
            .animation(.easeOut(duration: 0.24), value: isShining)
    }

    private var flashlightBody: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.22, blue: 0.24),
                            Color(red: 0.08, green: 0.09, blue: 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: imageHeight * 0.20, height: imageHeight * 0.075)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

            RoundedRectangle(cornerRadius: imageHeight * 0.018, style: .continuous)
                .fill(Color(red: 0.06, green: 0.07, blue: 0.08))
                .frame(width: imageHeight * 0.085, height: imageHeight * 0.095)
                .offset(x: -imageHeight * 0.095)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isShining ? 0.95 : 0.25),
                            Color.yellow.opacity(isShining ? 0.78 : 0.18),
                            Color.orange.opacity(0.18)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: imageHeight * 0.04
                    )
                )
                .frame(width: imageHeight * 0.05, height: imageHeight * 0.075)
                .offset(x: -imageHeight * 0.142)

            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: imageHeight * 0.09, height: imageHeight * 0.010)
                .offset(x: imageHeight * 0.02, y: -imageHeight * 0.018)
        }
        .rotationEffect(.degrees(isAiming ? -18 : -8))
        .offset(x: imageHeight * 0.33, y: -imageHeight * 0.37)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isAiming)
    }

    private var dustParticles: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(
                        Color.white.opacity(isShining ? 0.36 + randomValue(index: index, salt: 29) * 0.28 : 0.0)
                    )
                    .frame(
                        width: imageHeight * CGFloat(0.009 + randomValue(index: index, salt: 3) * 0.010),
                        height: imageHeight * CGFloat(0.009 + randomValue(index: index, salt: 3) * 0.010)
                    )
                    .blur(radius: 0.5)
                    .offset(
                        x: imageHeight * CGFloat(-0.26 + randomValue(index: index, salt: 7) * 0.52),
                        y: imageHeight * CGFloat(-0.30 + randomValue(index: index, salt: 11) * 0.32)
                    )
                    .animation(
                        .easeOut(duration: 0.38)
                        .delay(Double(index) * 0.018),
                        value: isShining
                    )
            }
        }
    }

    private func playAnimation() {
        isVisible = true
        isShining = false
        isAiming = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            isAiming = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            isShining = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.easeOut(duration: 0.25)) {
                isShining = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.30) {
            isAiming = false
            isVisible = false
        }
    }

    private func randomValue(index: Int, salt: Int) -> Double {
        let value = sin(Double(index * 139 + salt * 317)) * 43758.5453
        return value - floor(value)
    }
}

private struct FlashlightBeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX * 0.88, y: rect.minY + rect.height * 0.02))
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY * 0.92))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.maxY * 0.60),
            control: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY * 0.84)
        )
        path.closeSubpath()
        return path
    }
}

#Preview("Light Effect") {
    ZStack {
        Color.green.opacity(0.12).ignoresSafeArea()
        LightEffectView(trigger: 1, imageHeight: 360)
    }
}
