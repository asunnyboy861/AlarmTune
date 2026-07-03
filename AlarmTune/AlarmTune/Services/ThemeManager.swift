import SwiftUI

/// App theme manager - manages user-selected accent color theme
/// Singleton + ObservableObject pattern, consistent with AudioService/HapticService/VolumeMonitor
/// Persists selection via UserDefaults
final class ThemeManager: ObservableObject {

    static let shared = ThemeManager()

    /// All available themes
    static let allThemes: [AppTheme] = AppTheme.allCases

    /// Currently selected theme, persisted in UserDefaults
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: AppConstants.Theme.storageKey)
        }
    }

    private init() {
        let savedRaw = UserDefaults.standard.string(forKey: AppConstants.Theme.storageKey)
        if let saved = savedRaw, let theme = AppTheme(rawValue: saved) {
            currentTheme = theme
        } else {
            currentTheme = .blue
        }
    }

    /// The Color to apply as .tint() on the root view
    var accentColor: Color {
        currentTheme.color
    }
}

/// Available app themes
enum AppTheme: String, CaseIterable, Identifiable {
    case blue = "blue"
    case orange = "orange"
    case night = "night"
    case rose = "rose"
    case mint = "mint"

    var id: String { rawValue }

    /// Display name shown in Settings
    var displayName: String {
        switch self {
        case .blue:   return "Ocean Blue"
        case .orange: return "Sunrise Orange"
        case .night:  return "Midnight"
        case .rose:   return "Rose Pink"
        case .mint:   return "Fresh Mint"
        }
    }

    /// The SwiftUI Color for this theme
    var color: Color {
        switch self {
        case .blue:   return .blue
        case .orange: return Color(red: 1.0, green: 0.478, blue: 0.278)
        case .night:  return Color(red: 0.20, green: 0.20, blue: 0.35)
        case .rose:   return Color(red: 1.0, green: 0.412, blue: 0.580)
        case .mint:   return Color(red: 0.0, green: 0.780, blue: 0.620)
        }
    }

    /// SF Symbol icon for the theme picker
    var icon: String {
        switch self {
        case .blue:   return "water.waves"
        case .orange: return "sunrise.fill"
        case .night:  return "moon.stars.fill"
        case .rose:   return "heart.fill"
        case .mint:   return "leaf.fill"
        }
    }
}
