import Foundation

/// A finished file in the in-app library.
struct StoredFile: Identifiable, Equatable {
    let url: URL
    let size: Int64
    let modifiedAt: Date

    /// Sample rows reproduce the mockup before the library has real content.
    var isSample: Bool = false
    var sampleSizeText: String?
    var sampleDateText: String?

    var id: String { url.path }
    var name: String { url.lastPathComponent }
    var kind: FileKind { FileKind.infer(from: name) }

    var sizeText: String { sampleSizeText ?? Formatters.bytes(size) }
    var dateText: String { sampleDateText ?? Formatters.day(modifiedAt) }
    var subtitle: String { "\(sizeText) • \(dateText)" }
}
