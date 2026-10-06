//
//  AppThemeManager.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 25/07/26.
//

import SwiftUI
import Combine

struct ThemeColorOption: Identifiable, Equatable {
    let id = UUID()
    let startHex: String
    let endHex: String
    let iconName: String?

    var primaryColor: Color {
        Color.themeHex(startHex)
    }

    var secondaryColor: Color {
        Color.themeHex(endHex)
    }

    var colors: [Color] {
        [primaryColor, secondaryColor]
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var horizontalGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    static let defaultOption = ThemeColorOption(startHex: "ee9ca7", endHex: "ffdde1", iconName: nil)

    static let defaults: [ThemeColorOption] = [
        defaultOption,
        ThemeColorOption(startHex: "2591ff", endHex: "75a1ff", iconName: "AppIcon-Blue"),
        ThemeColorOption(startHex: "384135", endHex: "9d834f", iconName: "AppIcon-Olive"),
        ThemeColorOption(startHex: "ff9394", endHex: "f40c6e", iconName: "AppIcon-Red"),
        ThemeColorOption(startHex: "549378", endHex: "89af9f", iconName: "AppIcon-Teal"),
        ThemeColorOption(startHex: "009efd", endHex: "2af598", iconName: "AppIcon-Cyan"),
        ThemeColorOption(startHex: "3a1634", endHex: "91706c", iconName: "AppIcon-Burgundy"),
        ThemeColorOption(startHex: "AEBAF8", endHex: "6A6DD4", iconName: "AppIcon-Purple")
    ]

    static func buildDefaults() -> [ThemeColorOption] {
        defaults
    }
}

final class AppThemeManager: ObservableObject {

    private static let appearanceKey = "appearance_mode"
    private static let themeColorKey = "selected_theme_color_index"

    @Published var appearance: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey)
        }
    }

    @Published var selectedColorIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedColorIndex, forKey: Self.themeColorKey)
            
            let option = currentThemeOption
            if UIApplication.shared.alternateIconName != option.iconName {
                UIApplication.shared.setAlternateIconName(option.iconName) { error in
                    if let error = error {
                        print("Failed to set alternate icon: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    init() {
        let rawAppearance = UserDefaults.standard.string(forKey: Self.appearanceKey) ?? ""
        appearance = AppearanceMode(rawValue: rawAppearance) ?? .light

        if UserDefaults.standard.object(forKey: Self.themeColorKey) != nil {
            let savedIndex = UserDefaults.standard.integer(forKey: Self.themeColorKey)
            if ThemeColorOption.defaults.indices.contains(savedIndex) {
                selectedColorIndex = savedIndex
            } else {
                selectedColorIndex = 0
            }
        } else {
            selectedColorIndex = 0 // First color as default
        }
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    var currentThemeOption: ThemeColorOption {
        if ThemeColorOption.defaults.indices.contains(selectedColorIndex) {
            return ThemeColorOption.defaults[selectedColorIndex]
        }
        return ThemeColorOption.defaultOption
    }

    var primaryColor: Color {
        currentThemeOption.primaryColor
    }

    var secondaryColor: Color {
        currentThemeOption.secondaryColor
    }

    var primaryGradient: LinearGradient {
        currentThemeOption.gradient
    }

    var horizontalGradient: LinearGradient {
        currentThemeOption.horizontalGradient
    }
}

// MARK: - Adaptive Surface Colors & Hex Helper

extension Color {
    /// Default primary app color (`#EE9CA7`)
    static var defaultPrimary: Color {
        ThemeColorOption.defaultOption.primaryColor
    }

    /// Default secondary app color (`#FFDDE1`)
    static var defaultSecondary: Color {
        ThemeColorOption.defaultOption.secondaryColor
    }

    /// Card/sheet surface — white in light mode, `#252525` in dark mode.
    static var cardSurface: Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(white: 0.145, alpha: 1)   // #252525
                : .white
        })
    }

    /// Page / screen background — off-white in light mode, `#111111` in dark mode.
    static var pageSurface: Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(white: 0.067, alpha: 1)   // #111111
                : UIColor(white: 0.965, alpha: 1)   // #F6F6F6
        })
    }

    static func themeHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}
