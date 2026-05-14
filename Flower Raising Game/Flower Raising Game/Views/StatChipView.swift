import SwiftUI

struct StatChipView: View {
    let title: String
    let value: Double
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(spacing: 4) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.brown.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.52)

            ProgressView(value: value, total: 100)
                .tint(color)
                .scaleEffect(x: 1, y: 0.72, anchor: .center)

            Text("\(Int(value))%")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.brown.opacity(0.78))
        }
        .frame(minWidth: 52, maxWidth: .infinity)
    }
}
