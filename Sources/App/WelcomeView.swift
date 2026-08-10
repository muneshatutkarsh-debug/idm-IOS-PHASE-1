import SwiftUI

/// First-launch welcome screen. This is the one place with richer motion.
struct WelcomeView: View {

    @Environment(\.tokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onGetStarted: () -> Void

    @State private var logoShown = false
    @State private var sheenX: CGFloat = -140
    @State private var textShown = false
    @State private var rowsShown = 0
    @State private var buttonShown = false
    @State private var pulse = false

    private let features: [(symbol: String, title: String, subtitle: String)] = [
        ("bolt.fill", "Background downloads", "Keep downloading while you use other apps."),
        ("tray.and.arrow.down.fill", "Dynamic Island", "Watch progress from anywhere."),
        ("folder.fill", "Built-in files", "Preview, share, and manage everything.")
    ]

    var body: some View {
        ZStack {
            GradientBackground(animated: !reduceMotion)

            VStack(spacing: 0) {
                Spacer(minLength: 30)

                logoTile
                    .padding(.bottom, 22)

                Text("mDownloader")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(tokens.ink)
                    .opacity(textShown ? 1 : 0)
                    .offset(y: textShown ? 0 : 12)

                Text("Fast downloads, right on your iPhone.")
                    .font(.system(size: 15))
                    .foregroundColor(tokens.secondary)
                    .padding(.top, 6)
                    .opacity(textShown ? 1 : 0)
                    .offset(y: textShown ? 0 : 12)

                GlassCard {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 12) {
                            IconTile(symbol: feature.symbol)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(feature.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(tokens.ink)
                                Text(feature.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(tokens.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, Layout.rowHorizontal)
                        .padding(.vertical, Layout.rowVertical)
                        .opacity(rowsShown > index ? 1 : 0)
                        .offset(y: rowsShown > index ? 0 : 12)

                        if index < features.count - 1 {
                            HairlineDivider()
                        }
                    }
                }
                .padding(.top, 28)

                Spacer(minLength: 24)

                PrimaryGradientButton(title: "Get Started") {
                    onGetStarted()
                }
                .scaleEffect(pulse ? 1.03 : 1.0)
                .opacity(buttonShown ? 1 : 0)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, Layout.screenPadding)
        }
        .onAppear(perform: runIntro)
    }

    // MARK: - Logo

    private var logoTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Tokens.brandBottom.opacity(tokens.isDark ? 0.55 : 0.22), radius: 26, x: 0, y: 14)

            Image("LogoGlyph")
                .resizable()
                .scaledToFit()
                .padding(18)

            // Sheen sweep across the glass tile.
            if !reduceMotion {
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white.opacity(0.75), Color.white.opacity(0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 60)
                .rotationEffect(.degrees(18))
                .offset(x: sheenX)
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .scaleEffect(logoShown ? 1 : 0.8)
        .opacity(logoShown ? 1 : 0)
    }

    // MARK: - Choreography

    private func runIntro() {
        guard !reduceMotion else {
            withAnimation(.easeIn(duration: 0.35)) {
                logoShown = true
                textShown = true
                rowsShown = features.count
                buttonShown = true
            }
            return
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoShown = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.9)) {
                sheenX = 140
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 0.5)) { textShown = true }
        }

        for index in 0..<features.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(index) * 0.08) {
                withAnimation(.easeOut(duration: 0.45)) { rowsShown = index + 1 }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeOut(duration: 0.5)) { buttonShown = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
