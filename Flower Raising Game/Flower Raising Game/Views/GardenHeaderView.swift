import SwiftUI

struct GardenHeaderView: View {
    let weatherEmoji: String
    let weatherName: String
    let temperatureText: String
    let humidityText: String
    let windSpeedText: String
    let careStreakText: String

    var body: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 7) {
                HStack(spacing: 10) {
                    Text(weatherEmoji)
                        .font(.system(size: 34))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(weatherName)
                            .font(.subheadline.weight(.bold))
                        Text(temperatureText)
                            .font(.title3.monospacedDigit().weight(.semibold))

                        HStack(spacing: 6) {
                            WeatherMetricLabel(systemImage: "drop.fill", text: humidityText)
                            WeatherMetricLabel(systemImage: "wind", text: windSpeedText)
                        }
                        .padding(.top, 1)
                    }
                    .foregroundStyle(.brown.opacity(0.86))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .brown.opacity(0.12), radius: 14, y: 8)

                Label(careStreakText, systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green.opacity(0.9))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.76))
                    .clipShape(Capsule())
                    .shadow(color: .brown.opacity(0.08), radius: 8, y: 4)
            }
        }
    }
}

private struct WeatherMetricLabel: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.monospacedDigit().weight(.bold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.brown.opacity(0.72))
    }
}
