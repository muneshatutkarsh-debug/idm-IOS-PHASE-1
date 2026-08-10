import SwiftUI
import Combine

/// Persisted user settings (UserDefaults backed).
final class SettingsStore: ObservableObject {

    private enum Key {
        static let appearance = "settings.appearance"
        static let theme = "settings.theme"
        static let folder = "settings.downloadFolder"
        static let ask = "settings.askBeforeDownloading"
        static let welcome = "settings.hasSeenWelcome"
    }

    private let defaults = UserDefaults.standard

    @Published var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    @Published var theme: AppThemeKind {
        didSet {
            defaults.set(theme.rawValue, forKey: Key.theme)
            DownloadManager.shared.usesOriginalTheme = (theme == .original)
        }
    }

    @Published var downloadFolder: String {
        didSet {
            defaults.set(downloadFolder, forKey: Key.folder)
            DownloadManager.shared.downloadFolder = downloadFolder
        }
    }

    @Published var askBeforeDownloading: Bool {
        didSet { defaults.set(askBeforeDownloading, forKey: Key.ask) }
    }

    @Published var hasSeenWelcome: Bool {
        didSet { defaults.set(hasSeenWelcome, forKey: Key.welcome) }
    }

    init() {
        let storedAppearance = defaults.string(forKey: Key.appearance) ?? AppearanceMode.system.rawValue
        let storedTheme = defaults.string(forKey: Key.theme) ?? AppThemeKind.original.rawValue

        appearance = AppearanceMode(rawValue: storedAppearance) ?? .system
        theme = AppThemeKind(rawValue: storedTheme) ?? .original
        downloadFolder = defaults.string(forKey: Key.folder) ?? "Downloads"
        askBeforeDownloading = defaults.object(forKey: Key.ask) as? Bool ?? true
        hasSeenWelcome = defaults.bool(forKey: Key.welcome)

        DownloadManager.shared.downloadFolder = downloadFolder
        DownloadManager.shared.usesOriginalTheme = (theme == .original)
    }
}
