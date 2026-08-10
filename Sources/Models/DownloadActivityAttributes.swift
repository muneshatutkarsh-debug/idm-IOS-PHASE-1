import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Shared between the app and the widget extension: describes the Live Activity
/// shown on the Lock Screen and in the Dynamic Island.
struct DownloadActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        var progress: Double
        var speedText: String
        var etaText: String
        var isCompleted: Bool

        var percent: Int { Int((min(max(progress, 0), 1) * 100).rounded()) }
        var percentText: String { "\(percent)%" }
    }

    /// Static values for the life of the activity.
    var filename: String
    var downloadId: String
    var usesOriginalTheme: Bool

    var deepLink: URL? { URL(string: "mdownloader://download/\(downloadId)") }
}
#endif
