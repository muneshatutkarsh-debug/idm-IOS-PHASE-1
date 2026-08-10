import Foundation

enum DownloadStatus: String, Codable {
    case queued
    case downloading
    case paused
    case completed
    case failed

    var title: String {
        switch self {
        case .queued: return "Queued"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}

/// A single download tracked by `DownloadManager`.
struct DownloadItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var url: URL
    var filename: String
    var status: DownloadStatus = .queued
    var bytesWritten: Int64 = 0
    var totalBytes: Int64 = 0
    var speed: Double = 0
    var secondsRemaining: Double?
    var error: String?
    var createdAt: Date = Date()
    var destinationPath: String?

    /// Sample rows reproduce the mockup before the user adds real downloads.
    var isSample: Bool = false
    var sampleSizeText: String?

    var kind: FileKind { FileKind.infer(from: filename) }

    var progress: Double {
        if status == .completed { return 1 }
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(bytesWritten) / Double(totalBytes), 0), 1)
    }

    var percentText: String { Formatters.percent(progress) }

    var sizeText: String {
        if let sampleSizeText { return sampleSizeText }
        if totalBytes > 0 { return Formatters.bytes(totalBytes) }
        return Formatters.bytes(bytesWritten)
    }

    var isActive: Bool { status == .downloading || status == .queued }

    /// Row subtitle, per the design brief.
    var subtitle: String {
        switch status {
        case .downloading:
            return "\(sizeText) • \(Formatters.speed(speed))"
        case .completed:
            return "\(sizeText) • Completed"
        case .paused:
            return "\(Formatters.bytes(bytesWritten)) / \(sizeText) • Paused"
        case .queued:
            return "\(sizeText) • Queued"
        case .failed:
            return error ?? "Download failed"
        }
    }

    var destinationURL: URL? {
        guard let destinationPath else { return nil }
        return URL(fileURLWithPath: destinationPath)
    }
}
