import SwiftUI
import UIKit

@main
struct mDownloaderApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var settings = SettingsStore()
    @StateObject private var downloads = DownloadManager.shared
    @StateObject private var library = FileLibrary.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(downloads)
                .environmentObject(library)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Touch the shared manager early so the background session is restored.
        _ = DownloadManager.shared
        return true
    }

    /// iOS relaunches the app here when a background transfer finishes.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        DownloadManager.shared.backgroundCompletionHandler = completionHandler
    }
}
