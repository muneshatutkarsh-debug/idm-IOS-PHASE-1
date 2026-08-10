import Foundation

/// The kind of file a download / library row represents.
/// Drives the SF Symbol shown in the leading icon tile.
enum FileKind: String, Codable, CaseIterable {
    case video
    case audio
    case document
    case archive
    case image
    case other

    static func infer(from filename: String) -> FileKind {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "m4v", "avi", "mkv", "webm":
            return .video
        case "mp3", "m4a", "aac", "wav", "flac", "aiff":
            return .audio
        case "pdf", "txt", "rtf", "doc", "docx", "pages", "csv", "md":
            return .document
        case "zip", "xip", "rar", "7z", "tar", "gz", "bz2", "dmg":
            return .archive
        case "png", "jpg", "jpeg", "heic", "gif", "webp", "tiff", "bmp":
            return .image
        default:
            return .other
        }
    }

    var symbolName: String {
        switch self {
        case .video: return "play.fill"
        case .audio: return "music.note"
        case .document: return "doc.text.fill"
        case .archive: return "doc.zipper"
        case .image: return "photo.fill"
        case .other: return "doc.fill"
        }
    }

    var accessibilityName: String {
        switch self {
        case .video: return "Video"
        case .audio: return "Audio"
        case .document: return "Document"
        case .archive: return "Archive"
        case .image: return "Image"
        case .other: return "File"
        }
    }
}
