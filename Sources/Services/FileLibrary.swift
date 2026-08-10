import Foundation
import Combine

/// The in-app files library: everything that finished downloading lives in
/// `Documents/Downloads` (optionally inside one of the folders below).
final class FileLibrary: ObservableObject {

    static let shared = FileLibrary()

    @Published private(set) var files: [StoredFile] = []

    static let folderNames = ["Downloads", "Videos", "Music", "Documents"]

    private let fm = FileManager.default

    private init() {
        refresh()
    }

    // MARK: - Locations

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var downloadsRoot: URL {
        let url = documentsURL.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func folderURL(named name: String) -> URL {
        let root = FileLibrary.downloadsRoot
        guard name != "Downloads" else { return root }
        let url = root.appendingPathComponent(name, isDirectory: true)
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// A collision-free destination for a finished download.
    func uniqueDestination(for filename: String, folder: String) -> URL {
        let directory = folderURL(named: folder)
        var candidate = directory.appendingPathComponent(filename)
        guard fm.fileExists(atPath: candidate.path) else { return candidate }

        let base = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        var index = 2
        repeat {
            let name = ext.isEmpty ? "\(base) \(index)" : "\(base) \(index).\(ext)"
            candidate = directory.appendingPathComponent(name)
            index += 1
        } while fm.fileExists(atPath: candidate.path)

        return candidate
    }

    // MARK: - Contents

    func refresh() {
        let root = FileLibrary.downloadsRoot
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]

        var found: [StoredFile] = []

        func scan(_ directory: URL) {
            guard let contents = try? fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else { return }

            for url in contents {
                let values = try? url.resourceValues(forKeys: Set(keys))
                if values?.isDirectory == true {
                    scan(url)
                } else {
                    found.append(
                        StoredFile(
                            url: url,
                            size: Int64(values?.fileSize ?? 0),
                            modifiedAt: values?.contentModificationDate ?? Date()
                        )
                    )
                }
            }
        }

        scan(root)
        found.sort { $0.modifiedAt > $1.modifiedAt }

        if Thread.isMainThread {
            files = found
        } else {
            DispatchQueue.main.async { self.files = found }
        }
    }

    func delete(_ file: StoredFile) {
        guard !file.isSample else { return }
        try? fm.removeItem(at: file.url)
        refresh()
    }

    func deleteAll() {
        for file in files where !file.isSample {
            try? fm.removeItem(at: file.url)
        }
        refresh()
    }
}
