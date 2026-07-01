import SwiftUI

struct StatChipView: View {
    let title: String
    let value: Double
    let color: Color
    let systemImage: String
    let statusText: String?
    let statusColor: Color
    let idealRange: ClosedRange<Double>?

    init(
        title: String,
        value: Double,
        color: Color,
        systemImage: String,
        statusText: String? = nil,
        statusColor: Color = .orange,
        idealRange: ClosedRange<Double>? = nil
    ) {
        self.title = title
        self.value = value
        self.color = color
        self.systemImage = systemImage
        self.statusText = statusText
        self.statusColor = statusColor
        self.idealRange = idealRange
    }

    var body: some View {
        VStack(spacing: 3) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.brown.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.52)

            GeometryReader { geometry in
                let width = geometry.size.width
                let idealStart = CGFloat(clamped(idealRange?.lowerBound ?? 0) / 100) * width
                let idealWidth = CGFloat((clamped(idealRange?.upperBound ?? 0) - clamped(idealRange?.lowerBound ?? 0)) / 100) * width
                let progressWidth = CGFloat(clamped(value) / 100) * width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.brown.opacity(0.14))

                    if idealRange != nil {
                        Capsule()
                            .fill(.green.opacity(0.24))
                            .frame(width: max(idealWidth, 2))
                            .offset(x: idealStart)
                    }

                    Capsule()
                        .fill(color)
                        .frame(width: max(progressWidth, value > 0 ? 2 : 0))
                }
            }
            .frame(height: 5)

            HStack(spacing: 3) {
                Text("\(Int(value))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.brown.opacity(0.78))

                if let statusText {
                    Text(statusText)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(statusColor.opacity(0.12))
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(height: 16)
        }
        .frame(minWidth: 52, maxWidth: .infinity)
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }
}
