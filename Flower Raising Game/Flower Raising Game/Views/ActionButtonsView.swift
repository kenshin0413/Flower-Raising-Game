import SwiftUI

struct ActionButtonsView: View {
    let isDead: Bool
    let canWater: Bool
    let canGiveSunlight: Bool
    let canFeed: Bool
    let onReplant: () -> Void
    let onWater: () -> Void
    let onSunlight: () -> Void
    let onFeed: () -> Void

    var body: some View {
        if isDead {
            ActionCard(
                title: "植え替え",
                subtitle: "最初から育てる",
                systemImage: "arrow.triangle.2.circlepath",
                tint: .green,
                isEnabled: true,
                action: onReplant
            )
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ActionCard(
                    title: "水やり",
                    subtitle: canWater ? "水分 +18%" : "今日は完了",
                    systemImage: "drop.fill",
                    tint: .cyan,
                    isEnabled: canWater,
                    action: onWater
                )

                ActionCard(
                    title: "日光",
                    subtitle: canGiveSunlight ? "日光 +18%" : "今日は完了",
                    systemImage: "sun.max.fill",
                    tint: .orange,
                    isEnabled: canGiveSunlight,
                    action: onSunlight
                )

                ActionCard(
                    title: "肥料",
                    subtitle: canFeed ? "栄養 +20%" : "今日は完了",
                    systemImage: "leaf.fill",
                    tint: .green,
                    isEnabled: canFeed,
                    action: onFeed
                )
            }
        }
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isEnabled ? tint : .gray.opacity(0.65))

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isEnabled ? .brown.opacity(0.9) : .gray.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isEnabled ? tint : .gray.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(isEnabled ? 0.96 : 0.74),
                        (isEnabled ? tint : .gray).opacity(isEnabled ? 0.12 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.14), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
