import SwiftUI

struct SplashRootView: View {
    @State private var isShowingSplash = true
    @State private var splashDismissalScheduled = false

    var body: some View {
        ZStack {
            ContentView()
                .opacity(isShowingSplash ? 0 : 1)

            if isShowingSplash {
                AppSplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(2)
            }
        }
        .onAppear {
            scheduleSplashDismissalIfNeeded()
        }
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "flowerraising" else {
                return
            }

            // WidgetからのコールドスタートではURL配送時にsceneが一度切り替わることがあるため、
            // 通常のスプラッシュ待機をせずホーム画面を確実に表示します。
            dismissSplash(animated: false)
        }
    }

    private func scheduleSplashDismissalIfNeeded() {
        guard !splashDismissalScheduled else {
            return
        }
        splashDismissalScheduled = true

        // Viewのtaskはscene遷移でキャンセルされ得るため、起動演出の終了保証には
        // メインキューの期限付き処理を使用します。
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) {
            dismissSplash(animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                TrackingAuthorizationService.requestIfNeeded()
                startDeferredAppServices()
            }
        }
    }

    private func dismissSplash(animated: Bool) {
        guard isShowingSplash else {
            return
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.42)) {
                isShowingSplash = false
            }
        } else {
            isShowingSplash = false
        }
    }
}

private struct AppSplashView: View {
    @State private var isBlooming = false
    @State private var isFloating = false
    @State private var isTextVisible = false

    var body: some View {
        ZStack {
            splashBackground

            ForEach(0..<18, id: \.self) { index in
                SplashPetal(index: index, isActive: isBlooming)
            }

            VStack(spacing: 20) {
                Spacer(minLength: 0)

                flowerMark
                    .padding(.top, 22)

                VStack(spacing: 8) {
                    Text("はなそだて")
                        .font(.system(size: 29, weight: .black))
                        .foregroundStyle(.brown.opacity(0.86))
                        .opacity(isTextVisible ? 1 : 0)
                        .offset(y: isTextVisible ? 0 : 8)

                    Text("今日の空と、花の時間へ")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.brown.opacity(0.56))
                        .opacity(isTextVisible ? 1 : 0)
                        .offset(y: isTextVisible ? 0 : 8)
                }

                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == 1 ? Color.green.opacity(0.82) : Color.white.opacity(0.78))
                            .frame(width: 7, height: 7)
                            .scaleEffect(isFloating ? 1.18 : 0.72)
                            .animation(
                                .easeInOut(duration: 0.58)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.14),
                                value: isFloating
                            )
                    }
                }
                .padding(.top, 8)
                .opacity(isTextVisible ? 1 : 0)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.76)) {
                isBlooming = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                isFloating = true
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.28)) {
                isTextVisible = true
            }
        }
    }

    private var splashBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.82),
                    Color(red: 0.83, green: 0.95, blue: 0.86),
                    Color(red: 0.78, green: 0.92, blue: 0.98)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            Circle()
                .fill(Color.yellow.opacity(0.24))
                .frame(width: 210, height: 210)
                .blur(radius: 28)
                .offset(x: 104, y: -190)

            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: -118, y: 238)
        }
    }

    private var flowerMark: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.38))
                .frame(width: 245, height: 245)
                .blur(radius: 8)
                .scaleEffect(isBlooming ? 1 : 0.72)

            Circle()
                .stroke(.white.opacity(0.62), lineWidth: 1.4)
                .frame(width: 210, height: 210)
                .scaleEffect(isFloating ? 1.05 : 0.96)

            Image("splash")
                .resizable()
                .scaledToFit()
                .frame(width: 188, height: 188)
                .shadow(color: .green.opacity(0.20), radius: 18, y: 12)
                .scaleEffect(isBlooming ? 1 : 0.64)
                .offset(y: isFloating ? -7 : 2)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isFloating)

            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.yellow.opacity(0.92))
                .offset(x: 78, y: -74)
                .opacity(isBlooming ? 1 : 0)
                .scaleEffect(isBlooming ? 1 : 0.35)
        }
        .frame(height: 245)
    }
}

private struct SplashPetal: View {
    let index: Int
    let isActive: Bool

    var body: some View {
        Capsule()
            .fill(petalColor.opacity(isActive ? 0.48 : 0))
            .frame(width: 7 + randomValue(salt: 5) * 9, height: 15 + randomValue(salt: 11) * 17)
            .rotationEffect(.degrees(randomValue(salt: 17) * 180))
            .offset(
                x: CGFloat(-165 + randomValue(salt: 23) * 330),
                y: CGFloat(-270 + randomValue(salt: 29) * 540)
            )
            .scaleEffect(isActive ? 1 : 0.3)
            .animation(
                .easeOut(duration: 0.9)
                .delay(Double(index) * 0.025),
                value: isActive
            )
    }

    private var petalColor: Color {
        switch index % 4 {
        case 0:
            return Color(red: 0.99, green: 0.72, blue: 0.68)
        case 1:
            return Color(red: 0.98, green: 0.86, blue: 0.42)
        case 2:
            return Color(red: 0.52, green: 0.84, blue: 0.62)
        default:
            return .white
        }
    }

    private func randomValue(salt: Int) -> Double {
        let raw = (index + 1) * 1664525 + salt * 1013904223
        return Double(abs(raw % 1000)) / 1000.0
    }
}
