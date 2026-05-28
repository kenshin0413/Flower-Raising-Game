import SwiftUI

struct AnimatedWeatherBackgroundView: View {
    let weather: WeatherType
    let isDaytime: Bool
    let windSpeed: Double?
    let precipitation: Double?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { geometry in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let rain = rainSettings

                ZStack {
                    baseGradient

                    if isDaytime {
                        sunlightGlow(in: geometry.size, time: time)
                    } else {
                        nightLayer(in: geometry.size, time: time)
                    }

                    switch weather {
                    case .sunny:
                        sunnyLayer(in: geometry.size, time: time)
                    case .cloudy:
                        cloudLayer(in: geometry.size, time: time, density: 7, opacity: 0.50, color: Color(red: 0.78, green: 0.82, blue: 0.82))
                    case .rainy:
                        cloudLayer(in: geometry.size, time: time, density: 5, opacity: 0.36, color: Color(red: 0.72, green: 0.80, blue: 0.86))
                        rainLayer(in: geometry.size, time: time, count: rain.count, speed: rain.speed, opacity: rain.opacity)
                    case .stormy:
                        cloudLayer(in: geometry.size, time: time, density: 8, opacity: 0.52, color: Color(red: 0.50, green: 0.56, blue: 0.64))
                        rainLayer(in: geometry.size, time: time, count: max(rain.count, 62), speed: max(rain.speed, 360), opacity: max(rain.opacity, 0.50))
                        lightningLayer(in: geometry.size, time: time)
                    case .windy:
                        cloudLayer(in: geometry.size, time: time, density: 3, opacity: 0.24, color: .white)
                        windLayer(in: geometry.size, time: time)
                    }

                    if shouldShowWindOverlay {
                        windLayer(in: geometry.size, time: time, isOverlay: true)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
    }

    private var rainSettings: (count: Int, speed: Double, opacity: Double) {
        let amount = precipitation ?? (weather == .stormy ? 5.0 : 1.0)

        switch amount {
        case ..<0.2:
            return (24, 190, 0.22)
        case ..<1.0:
            return (38, 230, 0.32)
        case ..<3.0:
            return (54, 285, 0.42)
        case ..<8.0:
            return (72, 345, 0.54)
        default:
            return (88, 420, 0.64)
        }
    }

    private var shouldShowWindOverlay: Bool {
        guard weather != .windy, (windSpeed ?? 0) >= 24 else {
            return false
        }

        return true
    }

    private var baseGradient: some View {
        LinearGradient(
            colors: isDaytime ? daytimeColors : nighttimeColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var daytimeColors: [Color] {
        switch weather {
        case .sunny:
            return [
                Color(red: 1.00, green: 0.95, blue: 0.74),
                Color(red: 0.95, green: 1.00, blue: 0.82),
                Color(red: 0.77, green: 0.93, blue: 1.00)
            ]
        case .cloudy:
            return [
                Color(red: 0.86, green: 0.88, blue: 0.87),
                Color(red: 0.88, green: 0.94, blue: 0.88),
                Color(red: 0.82, green: 0.90, blue: 0.94)
            ]
        case .rainy:
            return [
                Color(red: 0.91, green: 0.96, blue: 0.98),
                Color(red: 0.87, green: 0.97, blue: 0.91),
                Color(red: 0.80, green: 0.92, blue: 0.99)
            ]
        case .stormy:
            return [
                Color(red: 0.82, green: 0.86, blue: 0.91),
                Color(red: 0.82, green: 0.93, blue: 0.87),
                Color(red: 0.72, green: 0.84, blue: 0.95)
            ]
        case .windy:
            return [
                Color(red: 0.95, green: 0.98, blue: 0.94),
                Color(red: 0.88, green: 0.98, blue: 0.90),
                Color(red: 0.84, green: 0.95, blue: 0.99)
            ]
        }
    }

    private var nighttimeColors: [Color] {
        [
            Color(red: 0.17, green: 0.22, blue: 0.32),
            Color(red: 0.18, green: 0.30, blue: 0.32),
            Color(red: 0.28, green: 0.40, blue: 0.36)
        ]
    }

    private func sunlightGlow(in size: CGSize, time: TimeInterval) -> some View {
        let pulse = 0.92 + sin(time * 0.9) * 0.08

        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(weather == .sunny ? 0.45 : 0.08),
                        Color.yellow.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: size.width * 0.60
                )
            )
            .frame(width: size.width * 0.95, height: size.width * 0.95)
            .scaleEffect(pulse)
            .offset(x: size.width * 0.18, y: -size.height * 0.20)
            .blur(radius: 8)
    }

    private func sunnyLayer(in size: CGSize, time: TimeInterval) -> some View {
        let drift = sin(time * 0.22) * 12

        return ZStack {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color.yellow.opacity(0.13))
                    .frame(width: 5, height: 58)
                    .rotationEffect(.degrees(Double(index) * 30 + time * 4))
                    .offset(x: size.width * 0.23 + drift, y: -size.height * 0.32)
                    .blur(radius: 1)
            }

            Circle()
                .fill(Color.yellow.opacity(0.30))
                .frame(width: 138, height: 138)
                .blur(radius: 14)
                .offset(x: size.width * 0.22 + drift, y: -size.height * 0.32)

            ForEach(0..<16, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: CGFloat(3 + index % 3), height: CGFloat(3 + index % 3))
                    .offset(
                        x: sparkleX(index: index, width: size.width, time: time),
                        y: sparkleY(index: index, height: size.height, time: time)
                    )
            }
        }
    }

    private func nightLayer(in size: CGSize, time: TimeInterval) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 74, height: 74)
                .offset(x: size.width * 0.30, y: -size.height * 0.35)
                .blur(radius: 1)

            ForEach(0..<18, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.18 + 0.10 * sin(time + Double(index))))
                    .frame(width: CGFloat(2 + index % 3), height: CGFloat(2 + index % 3))
                    .offset(
                        x: starX(index: index, width: size.width),
                        y: starY(index: index, height: size.height)
                    )
            }
        }
    }

    private func cloudLayer(in size: CGSize, time: TimeInterval, density: Int, opacity: Double, color: Color) -> some View {
        ZStack {
            ForEach(0..<density, id: \.self) { index in
                cloudShape
                    .fill(color.opacity(opacity))
                    .frame(width: CGFloat(185 + index * 20), height: CGFloat(64 + index * 6))
                    .blur(radius: CGFloat(8 + index % 2 * 4))
                    .offset(
                        x: cloudX(index: index, width: size.width, time: time),
                        y: CGFloat(70 + index * 58)
                    )
            }
        }
    }

    private var cloudShape: some Shape {
        Capsule()
    }

    private func rainLayer(in size: CGSize, time: TimeInterval, count: Int, speed: Double, opacity: Double) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let length = 14 + randomValue(index: index, salt: 3) * 18
                let width = 1.4 + randomValue(index: index, salt: 9) * 1.1
                let dropOpacity = opacity * (0.62 + randomValue(index: index, salt: 13) * 0.48)

                Capsule()
                    .fill(Color.blue.opacity(dropOpacity))
                    .frame(width: width, height: length)
                    .rotationEffect(.degrees(8 + randomValue(index: index, salt: 17) * 10))
                    .offset(
                        x: rainX(index: index, width: size.width, time: time),
                        y: rainY(index: index, height: size.height, time: time, speed: speed)
                    )
            }
        }
    }

    private func windLayer(in size: CGSize, time: TimeInterval, isOverlay: Bool = false) -> some View {
        let speedScale = max((windSpeed ?? 12) / 20, 0.8)
        let lineCount = isOverlay ? 7 : 13
        let opacity = isOverlay ? 0.14 : 0.26
        let lineHeight: CGFloat = isOverlay ? 2 : 3

        return ZStack {
            ForEach(0..<lineCount, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: CGFloat(74 + index % 4 * 24), height: lineHeight)
                    .blur(radius: 1)
                    .offset(
                        x: windX(index: index, width: size.width, time: time, speedScale: speedScale),
                        y: CGFloat(105 + index * (isOverlay ? 76 : 52))
                    )
            }
        }
    }

    private func lightningLayer(in size: CGSize, time: TimeInterval) -> some View {
        let shouldFlash = Int(time * 1.3) % 6 == 0

        return Rectangle()
            .fill(Color.white.opacity(shouldFlash ? 0.18 : 0))
            .animation(.easeOut(duration: 0.18), value: shouldFlash)
    }

    private func sparkleX(index: Int, width: CGFloat, time: TimeInterval) -> CGFloat {
        let base = Double((index * 53) % 100) / 100
        return width * CGFloat(base) - width * 0.5 + CGFloat(sin(time + Double(index)) * 10)
    }

    private func sparkleY(index: Int, height: CGFloat, time: TimeInterval) -> CGFloat {
        let base = Double((index * 29) % 100) / 100
        return height * CGFloat(base) - height * 0.20 + CGFloat(cos(time * 0.7 + Double(index)) * 8)
    }

    private func starX(index: Int, width: CGFloat) -> CGFloat {
        width * CGFloat(Double((index * 37) % 100) / 100) - width * 0.5
    }

    private func starY(index: Int, height: CGFloat) -> CGFloat {
        height * CGFloat(Double((index * 23) % 58) / 100) - height * 0.35
    }

    private func cloudX(index: Int, width: CGFloat, time: TimeInterval) -> CGFloat {
        let travel = width + 280
        let start = Double(index * 91)
        let x = (start + time * Double(10 + index * 3)).truncatingRemainder(dividingBy: Double(travel))
        return CGFloat(x) - travel / 2
    }

    private func rainX(index: Int, width: CGFloat, time: TimeInterval) -> CGFloat {
        let base = randomValue(index: index, salt: 29)
        let swaySpeed = 0.8 + randomValue(index: index, salt: 31) * 1.8
        let swayWidth = 5 + randomValue(index: index, salt: 37) * 18
        let diagonalDrift = (time * (5 + randomValue(index: index, salt: 41) * 18)).truncatingRemainder(dividingBy: 56) - 28

        return width * base - width / 2 + CGFloat(sin(time * swaySpeed + Double(index)) * swayWidth + diagonalDrift)
    }

    private func rainY(index: Int, height: CGFloat, time: TimeInterval, speed: Double) -> CGFloat {
        let travel = height + 120
        let start = randomValue(index: index, salt: 43) * Double(travel)
        let speedVariance = 0.72 + randomValue(index: index, salt: 47) * 0.58
        let y = (start + time * speed * speedVariance).truncatingRemainder(dividingBy: Double(travel))
        return CGFloat(y) - height / 2 - 60
    }

    private func windX(index: Int, width: CGFloat, time: TimeInterval, speedScale: Double) -> CGFloat {
        let travel = width + 220
        let start = Double(index * 79)
        let x = (start + time * 62 * speedScale).truncatingRemainder(dividingBy: Double(travel))
        return CGFloat(x) - width / 2 - 110
    }

    private func randomValue(index: Int, salt: Int) -> Double {
        let value = sin(Double(index * 127 + salt * 311)) * 43758.5453
        return value - floor(value)
    }
}

#Preview("Rain Background") {
    AnimatedWeatherBackgroundView(
        weather: .rainy,
        isDaytime: true,
        windSpeed: 8,
        precipitation: 4.0
    )
}
