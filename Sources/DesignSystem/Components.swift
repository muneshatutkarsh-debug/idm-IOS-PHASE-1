import SwiftUI

// MARK: - Background

struct GradientBackground: View {
    @Environment(\.tokens) private var tokens
    var animated: Bool = false
    @State private var drift = false

    var body: some View {
        LinearGradient(
            colors: [tokens.backgroundTop, tokens.backgroundBottom],
            startPoint: animated ? (drift ? .topLeading : .top) : .top,
            endPoint: animated ? (drift ? .bottom : .bottomTrailing) : .bottom
        )
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }
}

// MARK: - Glass surfaces

struct GlassSurface: ViewModifier {
    @Environment(\.tokens) private var tokens
    var cornerRadius: CGFloat = Tokens.cornerRadius
    var raised: Bool = false
    var highlightHeight: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill((raised ? tokens.cardRaised : tokens.card).opacity(tokens.cardOpacity))
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tokens.topHighlight)
                    .frame(height: highlightHeight)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(tokens.glassStroke, lineWidth: 1)
            )
            .shadow(color: tokens.shadowColor, radius: 18, x: 0, y: 10)
    }
}

extension View {
    func glassSurface(
        cornerRadius: CGFloat = Tokens.cornerRadius,
        raised: Bool = false,
        highlightHeight: CGFloat = 26
    ) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius, raised: raised, highlightHeight: highlightHeight))
    }
}

/// A rounded glass card that clips its rows.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var content: Content

    init(cornerRadius: CGFloat = Tokens.cornerRadius, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
            .glassSurface(cornerRadius: cornerRadius)
    }
}

// MARK: - Small building blocks

struct SectionHeader: View {
    @Environment(\.tokens) private var tokens
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(tokens.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconTile: View {
    @Environment(\.tokens) private var tokens
    let symbol: String
    var size: CGFloat = Layout.tileSize
    var filled: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous)
                .fill(filled ? AnyShapeStyle(tokens.brandGradient) : AnyShapeStyle(tokens.tile))
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(filled ? .white : tokens.accent)
        }
        .frame(width: size, height: size)
    }
}

struct HairlineDivider: View {
    @Environment(\.tokens) private var tokens

    var body: some View {
        Rectangle()
            .fill(tokens.hairline)
            .frame(height: 1)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Circular glass button used in screen headers.
struct CircleGlassButton: View {
    @Environment(\.tokens) private var tokens
    let symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tokens.accent)
                .frame(width: 38, height: 38)
                .glassSurface(cornerRadius: 19, highlightHeight: 14)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

/// Glass search field with a clear button.
struct GlassSearchField: View {
    @Environment(\.tokens) private var tokens
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tokens.secondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(tokens.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(tokens.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: Layout.searchHeight)
        .glassSurface(cornerRadius: Layout.searchRadius, highlightHeight: 14)
    }
}

/// Translucent track + blue gradient fill + red ball at the leading edge.
struct GlassProgressBar: View {
    @Environment(\.tokens) private var tokens
    let progress: Double
    var height: CGFloat = Layout.trackHeight
    var ballSize: CGFloat = Layout.ballSize

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fill = width * clamped

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(tokens.track)
                    .frame(height: height)

                Capsule(style: .continuous)
                    .fill(tokens.brandGradient)
                    .frame(width: max(fill, clamped > 0 ? height : 0), height: height)

                if clamped > 0 && clamped < 1 {
                    Circle()
                        .fill(Tokens.arrowRed)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
                        .frame(width: ballSize, height: ballSize)
                        .offset(x: min(max(fill - ballSize / 2, 0), width - ballSize))
                }
            }
            .frame(height: max(height, ballSize), alignment: .center)
            .animation(.easeInOut(duration: 0.25), value: clamped)
        }
        .frame(height: max(height, ballSize))
    }
}

// MARK: - Rows

struct DownloadRowView: View {
    @Environment(\.tokens) private var tokens
    let item: DownloadItem

    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbol: item.kind.symbolName)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.filename)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 4)

                    if item.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(tokens.accent)
                    } else {
                        Text(item.percentText)
                            .font(.system(size: 15, weight: .bold).monospacedDigit())
                            .foregroundColor(tokens.ink)
                    }
                }

                Text(item.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(item.status == .failed ? Tokens.arrowRed : tokens.secondary)
                    .lineLimit(1)

                if item.status == .downloading || item.status == .paused || item.status == .queued {
                    GlassProgressBar(progress: item.progress)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, Layout.rowHorizontal)
        .padding(.vertical, Layout.rowVertical)
        .contentShape(Rectangle())
    }
}

struct FileRowView: View {
    @Environment(\.tokens) private var tokens
    let file: StoredFile

    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbol: file.kind.symbolName)

            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tokens.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(file.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(tokens.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tokens.secondary.opacity(0.8))
        }
        .padding(.horizontal, Layout.rowHorizontal)
        .padding(.vertical, Layout.rowVertical)
        .contentShape(Rectangle())
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    @Environment(\.tokens) private var tokens
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(tokens.tile)
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(tokens.accent)
            }
            .frame(width: 68, height: 68)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tokens.ink)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(tokens.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous).fill(tokens.brandGradient)
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .glassSurface()
    }
}

// MARK: - Primary button

struct PrimaryGradientButton: View {
    @Environment(\.tokens) private var tokens
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tokens.brandGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Tokens.brandBottom.opacity(0.35), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Screen title

struct ScreenTitle: View {
    @Environment(\.tokens) private var tokens
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(tokens.ink)
    }
}
