import SwiftUI

struct WidgetSetupGuideView: View {
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                WidgetPromotionPreview()

                VStack(spacing: 8) {
                    Text("ホーム画面でも、見てるからね。")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("水分・日光・栄養をいつでも確認。放っておくと、花の機嫌がどんどん悪くなります。")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }

                VStack(spacing: 12) {
                    WidgetSetupStep(number: 1, symbol: "hand.tap.fill", title: "ホーム画面を長押し", detail: "アプリアイコンが揺れるまで押し続けます")
                    WidgetSetupStep(number: 2, symbol: "plus", title: "「編集」→「ウィジェットを追加」", detail: "画面左上の＋からも追加できます")
                    WidgetSetupStep(number: 3, symbol: "magnifyingglass", title: "「はなそだて」を検索", detail: "小または中サイズを選んで追加します")
                }

                VStack(spacing: 10) {
                    Button {
                        complete()
                    } label: {
                        Text("やり方がわかった")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 17, style: .continuous))

                    Text("iOSの仕様により、追加操作はホーム画面で行います。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.94, green: 0.99, blue: 0.95), Color(red: 1.0, green: 0.95, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("ウィジェット")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func complete() {
        if let onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }
}

private struct WidgetPromotionPreview: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.10, blue: 0.14), Color(red: 0.30, green: 0.02, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 15) {
                AngryFlowerIcon()

                VStack(alignment: .leading, spacing: 9) {
                    Text("ずっと待ってるんだけど！")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        PreviewStat(symbol: "drop.fill", value: "23", color: .cyan)
                        PreviewStat(symbol: "sun.max.fill", value: "51", color: .orange)
                        PreviewStat(symbol: "leaf.fill", value: "46", color: .green)
                    }

                    Text("タップしてお世話する  ›")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(16)
        }
        .frame(height: 165)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .red.opacity(0.23), radius: 18, y: 9)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("怒った花が水分、日光、栄養を知らせるウィジェットの見本")
    }
}

private struct AngryFlowerIcon: View {
    var body: some View {
        Image("widget_flower_angry")
            .resizable()
            .scaledToFit()
        .frame(width: 105, height: 110)
        .shadow(color: .black.opacity(0.28), radius: 6, y: 4)
    }
}

private struct PreviewStat: View {
    let symbol: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(value).monospacedDigit()
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.black.opacity(0.30), in: Capsule())
    }
}

private struct WidgetSetupStep: View {
    let number: Int
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle().fill(Color.green.opacity(0.15)).frame(width: 46, height: 46)
                Image(systemName: symbol).font(.headline.bold()).foregroundStyle(.green)
                Text("\(number)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(.green, in: Circle())
                    .offset(x: 18, y: -18)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
