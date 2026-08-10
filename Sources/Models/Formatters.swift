import Foundation

/// Shared display formatting for sizes, speeds, ETAs and dates.
enum Formatters {

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = false
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func bytes(_ value: Int64) -> String {
        guard value > 0 else { return "--" }
        return byteFormatter.string(fromByteCount: value)
    }

    static func speed(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond > 1 else { return "0 KB/s" }
        return byteFormatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    static func eta(_ seconds: Double?) -> String {
        guard let seconds, seconds.isFinite, seconds > 0 else { return "--" }
        if seconds < 60 {
            return "\(Int(seconds.rounded())) sec left"
        }
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 {
            return "\(minutes) min left"
        }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining == 0 ? "\(hours) hr left" : "\(hours) hr \(remaining) min left"
    }

    /// Today / Yesterday / "MMM d"
    static func day(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return dayFormatter.string(from: date)
    }

    static func percent(_ progress: Double) -> String {
        "\(Int((min(max(progress, 0), 1) * 100).rounded()))%"
    }
}
