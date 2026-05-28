import SwiftUI

struct ActionButtonsView: View {
    let isDead: Bool
    let isFullyBloomed: Bool
    let canWater: Bool
    let canGiveSunlight: Bool
    let canFeed: Bool
    let isCompact: Bool
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
                isCompact: isCompact,
                action: onReplant
            )
        } else if isFullyBloomed {
            ActionCard(
                title: "植え替え",
                subtitle: "新しい種を育てる",
                systemImage: "sparkles",
                tint: .green,
                isEnabled: true,
                isCompact: isCompact,
                action: onReplant
            )
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: isCompact ? 8 : 10), count: 3), spacing: isCompact ? 8 : 10) {
                ActionCard(
                    title: "水やり",
                    subtitle: canWater ? "水分 +9%" : "今日は完了",
                    systemImage: "drop.fill",
                    tint: .cyan,
                    isEnabled: canWater,
                    isCompact: isCompact,
                    action: onWater
                )

                ActionCard(
                    title: "ライト",
                    subtitle: canGiveSunlight ? "日光 +14%" : "今日は完了",
                    systemImage: "lightbulb.fill",
                    tint: .orange,
                    isEnabled: canGiveSunlight,
                    isCompact: isCompact,
                    action: onSunlight
                )

                ActionCard(
                    title: "肥料",
                    subtitle: canFeed ? "栄養 +7%" : "今日は完了",
                    systemImage: "leaf.fill",
                    tint: .green,
                    isEnabled: canFeed,
                    isCompact: isCompact,
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
    let isCompact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 2 : 4) {
                Image(systemName: systemImage)
                    .font(.system(size: isCompact ? 21 : 24, weight: .bold))
                    .foregroundStyle(isEnabled ? tint : .gray.opacity(0.9))

                Text(title)
                    .font((isCompact ? Font.caption : Font.subheadline).weight(.bold))
                    .foregroundStyle(isEnabled ? .brown.opacity(0.9) : .gray.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isEnabled ? tint : .gray.opacity(0.95))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isCompact ? 64 : 76)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(isEnabled ? 0.96 : 0.88),
                        (isEnabled ? tint : .gray).opacity(isEnabled ? 0.12 : 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isEnabled ? .white.opacity(0.85) : .gray.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: tint.opacity(isEnabled ? 0.14 : 0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
    }
}
