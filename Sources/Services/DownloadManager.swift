import Foundation
import Combine
import UIKit

/// Background download engine.
///
/// Uses a background `URLSession` so transfers continue while the app is in the
/// background, tracks bytes / speed / ETA per item and feeds both the UI rows
/// and the Live Activity.
final class DownloadManager: NSObject, ObservableObject {

    static let shared = DownloadManager()

    @Published private(set) var items: [DownloadItem] = []

    /// Set by the app delegate when iOS relaunches us for a finished transfer.
    var backgroundCompletionHandler: (() -> Void)?

    /// Destination folder name, mirrored from Settings.
    var downloadFolder: String = "Downloads"
    /// Theme flag mirrored into the Live Activity.
    var usesOriginalTheme: Bool = true

    private var session: URLSession!
    private var tasks: [UUID: URLSessionDownloadTask] = [:]
    private var resumeStore: [UUID: Data] = [:]
    private var samples: [UUID: (date: Date, bytes: Int64)] = [:]
    private var lastActivityPush: [UUID: Date] = [:]

    private let stateURL = FileLibrary.documentsURL.appendingPathComponent("downloads.json")

    private override init() {
        super.init()

        let configuration = URLSessionConfiguration.background(
            withIdentifier: "com.mdownloader.app.background"
        )
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.allowsCellularAccess = true

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        loadState()
    }

    // MARK: - Public API

    var hasRealItems: Bool { items.contains { !$0.isSample } }

    @discardableResult
    func add(urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return false }
        if components.scheme == nil { components.scheme = "https" }
        guard let url = components.url, url.host != nil else { return false }
        add(url: url)
        return true
    }

    func add(url: URL) {
        var item = DownloadItem(url: url, filename: DownloadManager.suggestedFilename(for: url))
        item.status = .downloading

        onMain {
            self.items.removeAll { $0.isSample }
            self.items.insert(item, at: 0)
            self.startTask(for: item)
            self.saveState()
        }
    }

    func pause(_ item: DownloadItem) {
        guard !item.isSample else { return }
        guard let task = tasks[item.id] else {
            update(item.id) { $0.status = .paused }
            return
        }

        task.cancel(byProducingResumeData: { data in
            self.onMain {
                if let data { self.resumeStore[item.id] = data }
                self.tasks[item.id] = nil
                self.update(item.id) {
                    $0.status = .paused
                    $0.speed = 0
                    $0.secondsRemaining = nil
                }
            }
        })
    }

    func resume(_ item: DownloadItem) {
        guard !item.isSample else { return }
        guard item.status == .paused || item.status == .failed else { return }

        update(item.id) {
            $0.status = .downloading
            $0.error = nil
        }

        if let data = resumeStore[item.id] {
            let task = session.downloadTask(withResumeData: data)
            task.taskDescription = item.id.uuidString
            tasks[item.id] = task
            resumeStore[item.id] = nil
            samples[item.id] = (Date(), item.bytesWritten)
            task.resume()
        } else if let refreshed = self.item(with: item.id) {
            startTask(for: refreshed)
        }

        if let refreshed = self.item(with: item.id) {
            LiveActivityController.shared.start(for: refreshed, usesOriginalTheme: usesOriginalTheme)
        }
    }

    func toggle(_ item: DownloadItem) {
        switch item.status {
        case .downloading, .queued: pause(item)
        case .paused, .failed: resume(item)
        case .completed: break
        }
    }

    func cancel(_ item: DownloadItem) {
        tasks[item.id]?.cancel()
        tasks[item.id] = nil
        resumeStore[item.id] = nil
        update(item.id) {
            $0.status = .failed
            $0.error = "Cancelled"
            $0.speed = 0
        }
        LiveActivityController.shared.end(id: item.id)
    }

    func remove(_ item: DownloadItem) {
        tasks[item.id]?.cancel()
        tasks[item.id] = nil
        resumeStore[item.id] = nil
        LiveActivityController.shared.end(id: item.id)
        onMain {
            self.items.removeAll { $0.id == item.id }
            self.saveState()
        }
    }

    func pauseAll() {
        for item in items where item.isActive { pause(item) }
    }

    func resumeAll() {
        for item in items where item.status == .paused || item.status == .failed { resume(item) }
    }

    func clearCompleted() {
        onMain {
            self.items.removeAll { $0.status == .completed }
            self.saveState()
        }
    }

    func item(with id: UUID) -> DownloadItem? {
        items.first { $0.id == id }
    }

    /// Shows the mockup's sample rows until the first real download is added.
    func seedSamplesIfNeeded() {
        guard items.isEmpty else { return }
        items = SampleData.downloads
    }

    // MARK: - Task plumbing

    private func startTask(for item: DownloadItem) {
        let task = session.downloadTask(with: item.url)
        task.taskDescription = item.id.uuidString
        tasks[item.id] = task
        samples[item.id] = (Date(), item.bytesWritten)
        task.resume()
        LiveActivityController.shared.start(for: item, usesOriginalTheme: usesOriginalTheme)
    }

    private func update(_ id: UUID, _ mutate: @escaping (inout DownloadItem) -> Void) {
        onMain {
            guard let index = self.items.firstIndex(where: { $0.id == id }) else { return }
            mutate(&self.items[index])
        }
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    static func suggestedFilename(for url: URL) -> String {
        let name = url.lastPathComponent
        if name.isEmpty || name == "/" {
            return "download-\(Int(Date().timeIntervalSince1970)).bin"
        }
        return name.removingPercentEncoding ?? name
    }

    // MARK: - Persistence

    private func saveState() {
        let snapshot = items.filter { !$0.isSample }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }

    private func loadState() {
        guard
            let data = try? Data(contentsOf: stateURL),
            let stored = try? JSONDecoder().decode([DownloadItem].self, from: data)
        else { return }

        // Anything that was mid-flight when we were terminated comes back paused.
        items = stored.map { item in
            var copy = item
            if copy.status == .downloading || copy.status == .queued {
                copy.status = .paused
                copy.speed = 0
                copy.secondsRemaining = nil
            }
            return copy
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard
            let description = downloadTask.taskDescription,
            let id = UUID(uuidString: description)
        else { return }

        let now = Date()
        var speed: Double = 0

        if let sample = samples[id] {
            let elapsed = now.timeIntervalSince(sample.date)
            if elapsed >= 0.5 {
                speed = Double(totalBytesWritten - sample.bytes) / elapsed
                samples[id] = (now, totalBytesWritten)
            }
        } else {
            samples[id] = (now, totalBytesWritten)
        }

        update(id) { item in
            item.status = .downloading
            item.bytesWritten = totalBytesWritten
            if totalBytesExpectedToWrite > 0 {
                item.totalBytes = totalBytesExpectedToWrite
            }
            if speed > 0 {
                item.speed = speed
                let remaining = Double(max(totalBytesExpectedToWrite - totalBytesWritten, 0))
                item.secondsRemaining = totalBytesExpectedToWrite > 0 ? remaining / max(speed, 1) : nil
            }
        }

        // Live Activities are rate limited - push at most once per second.
        let last = lastActivityPush[id] ?? .distantPast
        if now.timeIntervalSince(last) > 1 {
            lastActivityPush[id] = now
            onMain {
                if let item = self.item(with: id) {
                    LiveActivityController.shared.update(item)
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard
            let description = downloadTask.taskDescription,
            let id = UUID(uuidString: description)
        else { return }

        var filename = "download.bin"
        if let existing = items.first(where: { $0.id == id })?.filename {
            filename = existing
        } else if let suggested = downloadTask.response?.suggestedFilename {
            filename = suggested
        }

        if let suggested = downloadTask.response?.suggestedFilename,
           (filename as NSString).pathExtension.isEmpty,
           !(suggested as NSString).pathExtension.isEmpty {
            filename = suggested
        }

        let destination = FileLibrary.shared.uniqueDestination(for: filename, folder: downloadFolder)

        // The temporary file disappears as soon as this method returns.
        do {
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            try? FileManager.default.removeItem(at: destination)
            try? FileManager.default.copyItem(at: location, to: destination)
        }

        let size = (try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0

        update(id) { item in
            item.status = .completed
            item.speed = 0
            item.secondsRemaining = nil
            item.error = nil
            item.destinationPath = destination.path
            item.filename = destination.lastPathComponent
            if size > 0 { item.totalBytes = Int64(size) }
            item.bytesWritten = item.totalBytes
        }

        onMain {
            self.tasks[id] = nil
            self.samples[id] = nil
            FileLibrary.shared.refresh()
            if let item = self.item(with: id) {
                LiveActivityController.shared.complete(item)
            }
            self.saveState()
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard
            let description = task.taskDescription,
            let id = UUID(uuidString: description)
        else { return }

        guard let error = error as NSError? else {
            onMain { self.saveState() }
            return
        }

        // A pause produces a cancellation with resume data - not a failure.
        if let data = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            onMain {
                self.resumeStore[id] = data
                self.tasks[id] = nil
            }
            return
        }

        if error.code == NSURLErrorCancelled {
            onMain { self.tasks[id] = nil }
            return
        }

        update(id) { item in
            item.status = .failed
            item.error = error.localizedDescription
            item.speed = 0
            item.secondsRemaining = nil
        }

        onMain {
            self.tasks[id] = nil
            LiveActivityController.shared.end(id: id)
            self.saveState()
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}
