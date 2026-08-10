import SwiftUI

// MARK: - Theme / appearance choices

enum AppThemeKind: String, CaseIterable, Identifiable, Codable {
    case original
    case basic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: return "Original"
        case .basic: return "Basic"
        }
    }

    var subtitle: String {
        switch self {
        case .original: return "Themed with the logo"
        case .basic: return "Clean system look"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Colour tokens

struct Tokens {
    var theme: AppThemeKind
    var isDark: Bool

    var backgroundTop: Color
    var backgroundBottom: Color
    var card: Color
    var cardRaised: Color
    var ink: Color
    var secondary: Color
    var accent: Color
    var tile: Color
    var track: Color
    var hairline: Color

    /// How strongly the card tint sits on top of the blur.
    var cardOpacity: Double

    // Brand constants - identical in light and dark.
    static let brandTop = Color(hex: 0x4F72BE)
    static let brandBottom = Color(hex: 0x2E4088)
    static let arrowRed = Color(hex: 0xEC445B)

    static let cornerRadius: CGFloat = 18

    var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Tokens.brandTop, Tokens.brandBottom],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Slightly brighter along the top edge so a surface reads like glass.
    var glassStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isDark ? 0.22 : 0.85),
                hairline
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var topHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isDark ? 0.16 : 0.65),
                Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var shadowColor: Color {
        Color.black.opacity(isDark ? 0.45 : 0.10)
    }

    static func resolve(theme: AppThemeKind, scheme: ColorScheme) -> Tokens {
        let dark = scheme == .dark

        switch theme {
        case .original:
            return Tokens(
                theme: .original,
                isDark: dark,
                backgroundTop: dark ? Color(hex: 0x101A3E) : Color(hex: 0xF1F5FE),
                backgroundBottom: dark ? Color(hex: 0x090E24) : Color(hex: 0xE7EEFB),
                card: dark ? Color(hex: 0x151E3B) : Color(hex: 0xFFFFFF),
                cardRaised: dark ? Color(hex: 0x1D2748) : Color(hex: 0xF4F8FF),
                ink: dark ? Color(hex: 0xFFFFFF) : Color(hex: 0x0C1430),
                secondary: dark ? Color(hex: 0x9AA2B4) : Color(hex: 0x5C6474),
                accent: dark ? Color(hex: 0x6E90E6) : Color(hex: 0x34549A),
                tile: dark ? Color(hex: 0x1D2748) : Color(hex: 0xE3EAF9),
                track: dark ? Color.white.opacity(0.16) : Color(hex: 0x0C1430, alpha: 0.12),
                hairline: dark ? Color.white.opacity(0.08) : Color(hex: 0x121C3C, alpha: 0.10),
                cardOpacity: dark ? 0.60 : 0.65
            )

        case .basic:
            return Tokens(
                theme: .basic,
                isDark: dark,
                backgroundTop: dark ? Color(hex: 0x131315) : Color(hex: 0xF7F7F9),
                backgroundBottom: dark ? Color(hex: 0x0A0A0C) : Color(hex: 0xEFEFF2),
                card: dark ? Color(hex: 0x1C1C1E) : Color(hex: 0xFFFFFF),
                cardRaised: dark ? Color(hex: 0x2C2C2E) : Color(hex: 0xF2F2F7),
                ink: dark ? Color(hex: 0xFFFFFF) : Color(hex: 0x111114),
                secondary: dark ? Color(hex: 0x98989F) : Color(hex: 0x6C6C70),
                accent: dark ? Color(hex: 0x0A84FF) : Color(hex: 0x007AFF),
                tile: dark ? Color(hex: 0x2C2C2E) : Color(hex: 0xEAEAEF),
                track: dark ? Color.white.opacity(0.18) : Color.black.opacity(0.12),
                hairline: dark ? Color.white.opacity(0.10) : Color.black.opacity(0.10),
                cardOpacity: dark ? 0.92 : 0.94
            )
        }
    }
}

// MARK: - Environment plumbing

private struct TokensEnvironmentKey: EnvironmentKey {
    static let defaultValue: Tokens = Tokens.resolve(theme: .original, scheme: .light)
}

extension EnvironmentValues {
    var tokens: Tokens {
        get { self[TokensEnvironmentKey.self] }
        set { self[TokensEnvironmentKey.self] = newValue }
    }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

enum Layout {
    static let screenPadding: CGFloat = 20
    static let sectionGap: CGFloat = 18
    static let headerGap: CGFloat = 8
    static let bottomInset: CGFloat = 130
    static let rowHorizontal: CGFloat = 14
    static let rowVertical: CGFloat = 12
    static let settingsRowVertical: CGFloat = 11
    static let tileSize: CGFloat = 40
    static let settingsTileSize: CGFloat = 38
    static let tileRadius: CGFloat = 11
    static let searchHeight: CGFloat = 42
    static let searchRadius: CGFloat = 12
    static let trackHeight: CGFloat = 7
    static let ballSize: CGFloat = 13
}
