import SwiftUI

struct GrowthStageCardView: View {
    let stageName: String
    let stageProgress: Double

    var body: some View {
        HStack(spacing: 10) {
            Label("成長ステージ", systemImage: "leaf.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)

            Text(stageName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.brown.opacity(0.88))

            Spacer(minLength: 8)

            ProgressView(value: stageProgress, total: 100)
                .tint(.green)
                .frame(width: 58)

            Text("\(Int(stageProgress.rounded()))%")
                .font(.callout.monospacedDigit().weight(.bold))
                .foregroundStyle(.brown.opacity(0.78))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .brown.opacity(0.10), radius: 10, y: 5)
    }
}
