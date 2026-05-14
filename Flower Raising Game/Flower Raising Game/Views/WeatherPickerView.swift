import SwiftUI

struct WeatherPickerView: View {
    @Binding var selectedWeather: WeatherType
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日の仮天気")
                    .font(.subheadline.weight(.bold))

                Spacer()

                Text("\(selectedWeather.emoji) \(selectedWeather.displayName)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.brown.opacity(0.82))
            }

            Picker("今日の仮天気", selection: $selectedWeather) {
                ForEach(WeatherType.allCases) { weather in
                    Text("\(weather.emoji) \(weather.displayName)")
                        .tag(weather)
                }
            }
            .pickerStyle(.segmented)

            Button(action: onApply) {
                Label("選んだ天気を反映", systemImage: "cloud.sun.fill")
                    .frame(maxWidth: .infinity)
            }
            .font(.subheadline.weight(.bold))
            .buttonStyle(.borderedProminent)
            .tint(selectedWeather.tintColor)
        }
        .padding(12)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .green.opacity(0.10), radius: 10, y: 5)
    }
}
