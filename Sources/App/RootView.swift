import SwiftUI
import UIKit

enum AppTab: String, CaseIterable, Identifiable {
    case downloads
    case files
    case settings

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .downloads: return "tray.and.arrow.down.fill"
        case .files: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .downloads: return "Downloads"
        case .files: return "Files"
        case .settings: return "Settings"
        }
    }
}

struct RootView: View {

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var downloads: DownloadManager
    @EnvironmentObject private var library: FileLibrary
    @Environment(\.colorScheme) private var colorScheme

    @State private var tab: AppTab = .downloads
    @State private var showAddSheet = false
    @State private var pendingURL: String = ""
    @State private var showConfirmSheet = false
    @State private var focusedDownload: DownloadItem?

    private var tokens: Tokens {
        Tokens.resolve(theme: settings.theme, scheme: colorScheme)
    }

    var body: some View {
        ZStack {
            GradientBackground()

            Group {
                switch tab {
                case .downloads:
                    DownloadsView(showAddSheet: $showAddSheet, focusedDownload: $focusedDownload)
                case .files:
                    FilesView()
                case .settings:
                    SettingsView()
                }
            }
            .transition(.opacity)

            VStack {
                Spacer()
                FloatingTabDock(selection: $tab)
                    .padding(.bottom, 16)
            }
            .ignoresSafeArea(.keyboard)

            if !settings.hasSeenWelcome {
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        settings.hasSeenWelcome = true
                        tab = .downloads
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(10)
            }
        }
        .environment(\.tokens, tokens)
        .sheet(isPresented: $showAddSheet) {
            AddDownloadSheet { urlString in
                _ = downloads.add(urlString: urlString)
            }
            .environment(\.tokens, tokens)
        }
        .sheet(item: $focusedDownload) { item in
            DownloadDetailView(itemId: item.id)
                .environment(\.tokens, tokens)
                .environmentObject(downloads)
        }
        .alert("Start this download?", isPresented: $showConfirmSheet) {
            Button("Cancel", role: .cancel) { pendingURL = "" }
            Button("Download") {
                _ = downloads.add(urlString: pendingURL)
                pendingURL = ""
                tab = .downloads
            }
        } message: {
            Text(pendingURL)
        }
        .onAppear {
            downloads.seedSamplesIfNeeded()
            library.refresh()
        }
        .onOpenURL { url in
            handle(url)
        }
        .animation(.easeInOut(duration: 0.25), value: tab)
    }

    // MARK: - Deep links

    private func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "mdownloader" else { return }

        let host = (url.host ?? "").lowercased()

        switch host {
        case "add":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let value = components?.queryItems?.first(where: { $0.name == "url" })?.value,
                  !value.isEmpty else { return }

            tab = .downloads
            if settings.askBeforeDownloading {
                pendingURL = value
                showConfirmSheet = true
            } else {
                _ = downloads.add(urlString: value)
            }

        case "download":
            let identifier = url.lastPathComponent
            tab = .downloads
            if let uuid = UUID(uuidString: identifier), let item = downloads.item(with: uuid) {
                focusedDownload = item
            }

        default:
            break
        }
    }
}

// MARK: - Floating glass dock

struct FloatingTabDock: View {
    @Environment(\.tokens) private var tokens
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = tab
                    }
                } label: {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selection == tab ? tokens.accent : tokens.secondary)
                        .frame(width: 64, height: 44)
                        .background(
                            ZStack {
                                if selection == tab {
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(tokens.cardRaised.opacity(tokens.isDark ? 0.85 : 0.95))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                                .strokeBorder(Color.white.opacity(tokens.isDark ? 0.16 : 0.75), lineWidth: 1)
                                        )
                                }
                            }
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(tab.title)
            }
        }
        .padding(6)
        .glassSurface(cornerRadius: 24, highlightHeight: 18)
    }
}

// MARK: - Add download sheet

struct AddDownloadSheet: View {
    @Environment(\.tokens) private var tokens
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    let onAdd: (String) -> Void

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Add Download")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(tokens.ink)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(tokens.secondary)
                            .frame(width: 34, height: 34)
                            .glassSurface(cornerRadius: 17, highlightHeight: 12)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }

                SectionHeader(title: "Link")

                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(tokens.secondary)

                    TextField("https://example.com/file.mp4", text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(tokens.ink)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)

                    Button {
                        if let clipboard = UIPasteboard.general.string {
                            text = clipboard
                        }
                    } label: {
                        Text("Paste")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(tokens.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .frame(height: Layout.searchHeight)
                .glassSurface(cornerRadius: Layout.searchRadius, highlightHeight: 14)

                PrimaryGradientButton(title: "Start Download") {
                    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !value.isEmpty else { return }
                    onAdd(value)
                    dismiss()
                }

                Spacer()
            }
            .padding(Layout.screenPadding)
        }
        .presentationDetents([.height(300)])
    }
}
