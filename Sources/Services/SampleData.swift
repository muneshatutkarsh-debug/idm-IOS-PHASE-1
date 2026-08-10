import Foundation

/// The rows shown in the reference mockups. They are displayed until the user
/// adds their first real download / file, so a fresh install looks exactly like
/// the design.
enum SampleData {

    static var downloads: [DownloadItem] {
        [
            sample(
                name: "Big Buck Bunny 4K.mp4",
                sizeText: "420 MB",
                status: .downloading,
                progress: 0.62,
                speed: 12.4 * 1_000_000
            ),
            sample(
                name: "Xcode_16.4.xip",
                sizeText: "7.2 GB",
                status: .downloading,
                progress: 0.34,
                speed: 1.8 * 1_000_000
            ),
            sample(
                name: "lofi-mix.zip",
                sizeText: "86 MB",
                status: .completed,
                progress: 1,
                speed: 0
            )
        ]
    }

    static var files: [StoredFile] {
        [
            file("Big Buck Bunny 4K.mp4", "420 MB", "Today"),
            file("Xcode_16.4.xip", "7.2 GB", "Today"),
            file("Invoice_July.pdf", "240 KB", "Yesterday"),
            file("lofi-mix.zip", "86 MB", "Aug 6"),
            file("wallpaper_5k.png", "5.1 MB", "Aug 5")
        ]
    }

    // MARK: - Builders

    private static func sample(
        name: String,
        sizeText: String,
        status: DownloadStatus,
        progress: Double,
        speed: Double
    ) -> DownloadItem {
        let total: Int64 = 1_000_000
        var item = DownloadItem(
            url: URL(string: "https://example.com/\(name)") ?? URL(fileURLWithPath: "/\(name)"),
            filename: name
        )
        item.status = status
        item.totalBytes = total
        item.bytesWritten = Int64(Double(total) * progress)
        item.speed = speed
        item.secondsRemaining = status == .downloading ? 240 : nil
        item.isSample = true
        item.sampleSizeText = sizeText
        return item
    }

    private static func file(_ name: String, _ size: String, _ date: String) -> StoredFile {
        StoredFile(
            url: FileLibrary.downloadsRoot.appendingPathComponent(name),
            size: 0,
            modifiedAt: Date(),
            isSample: true,
            sampleSizeText: size,
            sampleDateText: date
        )
    }
}
