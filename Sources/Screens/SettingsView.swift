import SwiftUI

struct SettingsView: View {

    @Environment(\.tokens) private var tokens
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {

                ScreenTitle(text: "Settings")

                appHeaderCard

                section("Appearance") {
                    appearancePicker
                        .padding(.horizontal, Layout.rowHorizontal)
                        .padding(.vertical, Layout.rowHorizontal)
                }

                section("Theme") {
                    ForEach(Array(AppThemeKind.allCases.enumerated()), id: \.element.id) { index, theme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                settings.theme = theme
                            }
                        } label: {
                            themeRow(theme)
                        }
                        .buttonStyle(PressScaleButtonStyle(scale: 0.99))

                        if index < AppThemeKind.allCases.count - 1 {
                            HairlineDivider()
                        }
                    }
                }

                section("General") {
                    folderRow
                    HairlineDivider()
                    askRow
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Layout.screenPadding)
            .padding(.bottom, Layout.bottomInset)
        }
    }

    // MARK: - Pieces

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.headerGap) {
            SectionHeader(title: title)
            GlassCard { content() }
        }
    }

    private var appHeaderCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(tokens.isDark ? 0.4 : 0.12), radius: 10, x: 0, y: 6)
                    Image("LogoGlyph")
                        .resizable()
                        .scaledToFit()
                        .padding(9)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text("mDownloader")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(tokens.ink)
                    Text("Version \(AppInfo.version)")
                        .font(.system(size: 13))
                        .foregroundColor(tokens.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.rowHorizontal)
            .padding(.vertical, 14)
        }
    }

    private var appearancePicker: some View {
        Picker("Appearance", selection: $settings.appearance) {
            ForEach(AppearanceMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private func themeRow(_ theme: AppThemeKind) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous)
                .fill(swatch(for: theme))
                .frame(width: Layout.settingsTileSize, height: Layout.settingsTileSize)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous)
                        .strokeBorder(tokens.hairline, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tokens.ink)
                Text(theme.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(tokens.secondary)
            }

            Spacer(minLength: 8)

            if settings.theme == theme {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tokens.accent)
            }
        }
        .padding(.horizontal, Layout.rowHorizontal)
        .padding(.vertical, Layout.settingsRowVertical)
        .contentShape(Rectangle())
    }

    private func swatch(for theme: AppThemeKind) -> LinearGradient {
        switch theme {
        case .original:
            return LinearGradient(
                colors: [Tokens.brandTop, Tokens.brandBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .basic:
            return LinearGradient(
                colors: [
                    tokens.isDark ? Color(hex: 0x2C2C2E) : Color(hex: 0xF2F2F7),
                    tokens.isDark ? Color(hex: 0x1C1C1E) : Color(hex: 0xE3E3E8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var folderRow: some View {
        Menu {
            ForEach(FileLibrary.folderNames, id: \.self) { name in
                Button {
                    settings.downloadFolder = name
                } label: {
                    if settings.downloadFolder == name {
                        Label(name, systemImage: "checkmark")
                    } else {
                        Text(name)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                IconTile(symbol: "folder.fill", size: Layout.settingsTileSize)

                Text("Download Folder")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tokens.ink)

                Spacer(minLength: 8)

                Text(settings.downloadFolder)
                    .font(.system(size: 15))
                    .foregroundColor(tokens.secondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tokens.secondary.opacity(0.8))
            }
            .padding(.horizontal, Layout.rowHorizontal)
            .padding(.vertical, Layout.settingsRowVertical)
            .contentShape(Rectangle())
        }
    }

    private var askRow: some View {
        HStack(spacing: 12) {
            IconTile(symbol: "bell.badge.fill", size: Layout.settingsTileSize)

            Text("Ask before downloading")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tokens.ink)

            Spacer(minLength: 8)

            Toggle("", isOn: $settings.askBeforeDownloading)
                .labelsHidden()
                .tint(tokens.accent)
        }
        .padding(.horizontal, Layout.rowHorizontal)
        .padding(.vertical, Layout.settingsRowVertical)
    }
}

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}
