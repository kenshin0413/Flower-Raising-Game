import SwiftUI

struct StatRowView: View {
    let title: String
    let value: Double
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(Int(value))%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: value, total: 100)
                .tint(color)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
        }
    }
}
