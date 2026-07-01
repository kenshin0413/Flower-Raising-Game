import SwiftUI

struct GardenHeaderView: View {
    let weatherEmoji: String
    let weatherName: String
    let temperatureText: String
    let humidityText: String
    let windSpeedText: String
    let careStreakText: String
    let onGachaTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 7) {
                HStack(spacing: 6) {
                    Text(weatherEmoji)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(weatherName)
                            .font(.caption.weight(.bold))
                        Text(temperatureText)
                            .font(.callout.monospacedDigit().weight(.semibold))

                        HStack(spacing: 4) {
                            WeatherMetricLabel(systemImage: "drop.fill", text: humidityText)
                            WeatherMetricLabel(systemImage: "wind", text: windSpeedText)
                        }
                        .padding(.top, 1)
                    }
                    .foregroundStyle(.brown.opacity(0.86))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .brown.opacity(0.12), radius: 14, y: 8)

                HStack(spacing: 5) {
                    Label(careStreakText, systemImage: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.76))
                        .clipShape(Capsule())
                        .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)

                    Button(action: onGachaTap) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.green.opacity(0.82))
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.78))
                            .clipShape(Circle())
                            .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("ガチャ")

                    Button(action: onSettingsTap) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.brown.opacity(0.72))
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.78))
                            .clipShape(Circle())
                            .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("設定")
                }
                .frame(maxWidth: 150, alignment: .trailing)
            }
        }
    }
}

private struct WeatherMetricLabel: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 9, weight: .bold, design: .default).monospacedDigit())
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.brown.opacity(0.72))
    }
}
