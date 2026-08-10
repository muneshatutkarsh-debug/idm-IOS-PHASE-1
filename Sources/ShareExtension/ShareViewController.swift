import UIKit
import Social
import UniformTypeIdentifiers

/// "Download with mDownloader" share sheet action.
///
/// Grabs the shared URL (or a URL inside shared text) and hands it to the app
/// through the `mdownloader://add?url=` deep link.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractURL()
    }

    private func extractURL() {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = item.attachments
        else {
            finish(nil)
            return
        }

        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(urlType) }) {
            provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] value, _ in
                let url = (value as? URL) ?? URL(string: (value as? String) ?? "")
                DispatchQueue.main.async { self?.finish(url?.absoluteString) }
            }
            return
        }

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(textType) }) {
            provider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] value, _ in
                let text = (value as? String) ?? ""
                DispatchQueue.main.async { self?.finish(ShareViewController.firstURL(in: text)) }
            }
            return
        }

        finish(nil)
    }

    private static func firstURL(in text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let match = detector?.firstMatch(in: text, options: [], range: range)
        return match?.url?.absoluteString
    }

    private func finish(_ urlString: String?) {
        if
            let urlString,
            let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
            let deepLink = URL(string: "mdownloader://add?url=\(encoded)")
        {
            open(deepLink)
        }

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    /// Extensions cannot call `UIApplication.shared.open`, so walk the responder
    /// chain to the hosting application object.
    private func open(_ url: URL) {
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:")

        while let current = responder {
            if current.responds(to: selector), current !== self {
                _ = current.perform(selector, with: url)
                return
            }
            responder = current.next
        }

        extensionContext?.open(url, completionHandler: nil)
    }
}
