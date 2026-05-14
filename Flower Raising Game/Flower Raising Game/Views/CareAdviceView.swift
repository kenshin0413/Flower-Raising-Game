import SwiftUI

struct CareAdviceView: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 18)

            Text(text)
                .font(.caption.weight(.bold))
                .foregroundStyle(.brown.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .brown.opacity(0.06), radius: 7, y: 3)
    }
}
