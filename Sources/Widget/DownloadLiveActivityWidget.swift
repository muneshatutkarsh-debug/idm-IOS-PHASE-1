import SwiftUI
import WidgetKit
import ActivityKit

@main
struct mDownloaderWidgetBundle: WidgetBundle {
    var body: some Widget {
        DownloadLiveActivityWidget()
    }
}

struct DownloadLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(LiveActivityPalette.lockScreenBackground(context.attributes.usesOriginalTheme))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in

            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(LiveActivityPalette.gradient(context.attributes.usesOriginalTheme))
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 38, height: 38)
                    .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.filename)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(context.state.isCompleted
                             ? "Completed"
                             : "Downloading \u{2022} \(context.state.speedText)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.percentText)
                        .font(.title3.bold().monospacedDigit())
                        .foregroundColor(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        LiveActivityProgressBar(
                            progress: context.state.progress,
                            original: context.attributes.usesOriginalTheme,
                            height: 8,
                            ballSize: 13
                        )

                        HStack {
                            Text(context.state.isCompleted ? "Done" : context.state.speedText)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(context.state.etaText)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }

            } compactLeading: {
                ProgressRing(
                    progress: context.state.progress,
                    original: context.attributes.usesOriginalTheme,
                    size: 20,
                    lineWidth: 3
                )
            } compactTrailing: {
                Group {
                    if context.state.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(LiveActivityPalette.accent(context.attributes.usesOriginalTheme))
                    } else {
                        Text(context.state.speedText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(LiveActivityPalette.accent(context.attributes.usesOriginalTheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(width: 62)
            } minimal: {
                ProgressRing(
                    progress: context.state.progress,
                    original: context.attributes.usesOriginalTheme,
                    size: 18,
                    lineWidth: 3
                )
            }
            .widgetURL(context.attributes.deepLink)
            .keylineTint(LiveActivityPalette.accent(context.attributes.usesOriginalTheme))
        }
    }
}

// MARK: - Lock screen

struct LockScreenLiveActivityView: View {

    let context: ActivityViewContext<DownloadActivityAttributes>

    private var original: Bool { context.attributes.usesOriginalTheme }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LiveActivityPalette.gradient(original))
                Image(systemName: "arrow.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(context.attributes.filename)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if context.state.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(context.state.percentText)
                            .font(.title3.bold().monospacedDigit())
                            .foregroundColor(.white)
                    }
                }

                Text("mDownloader \u{2022} \(context.state.percentText)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)

                LiveActivityProgressBar(
                    progress: context.state.progress,
                    original: original,
                    height: 7,
                    ballSize: 13
                )

                HStack {
                    Text(context.state.isCompleted ? "Done" : context.state.speedText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(context.state.etaText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Shared pieces

enum LiveActivityPalette {

    static func gradient(_ original: Bool) -> LinearGradient {
        LinearGradient(
            colors: original
                ? [Tokens.brandTop, Tokens.brandBottom]
                : [Color(hex: 0x3A3A3C), Color(hex: 0x1C1C1E)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func accent(_ original: Bool) -> Color {
        original ? Color(hex: 0x6E90E6) : Color(hex: 0x0A84FF)
    }

    static func lockScreenBackground(_ original: Bool) -> Color {
        original ? Color(hex: 0x101A3E).opacity(0.92) : Color(hex: 0x121214).opacity(0.92)
    }

    static let ball = Tokens.arrowRed
}

struct LiveActivityProgressBar: View {

    let progress: Double
    let original: Bool
    var height: CGFloat = 7
    var ballSize: CGFloat = 13

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fill = width * clamped

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(height: height)

                Capsule(style: .continuous)
                    .fill(LiveActivityPalette.gradient(original))
                    .frame(width: max(fill, clamped > 0 ? height : 0), height: height)

                if clamped > 0 && clamped < 1 {
                    Circle()
                        .fill(LiveActivityPalette.ball)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
                        .frame(width: ballSize, height: ballSize)
                        .offset(x: min(max(fill - ballSize / 2, 0), max(width - ballSize, 0)))
                }
            }
            .frame(height: max(height, ballSize), alignment: .center)
        }
        .frame(height: max(height, ballSize))
    }
}

struct ProgressRing: View {

    let progress: Double
    let original: Bool
    var size: CGFloat = 20
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.20), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(min(progress, 1), 0.02))
                .stroke(
                    AngularGradient(
                        colors: original
                            ? [Tokens.brandTop, Tokens.brandBottom, Tokens.brandTop]
                            : [Color(hex: 0x0A84FF), Color(hex: 0x4AA8FF), Color(hex: 0x0A84FF)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
