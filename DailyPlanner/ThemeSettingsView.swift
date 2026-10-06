//
//  ThemeSettingsView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 25/07/26.
//

import SwiftUI
import Lottie

// MARK: - Model

enum AppearanceMode: String, CaseIterable {
    case light, dark, system

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Theme Settings Screen

struct ThemeSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager

    @AppStorage("checkInMethod") private var checkInMethod: String = "Swipe right to check in"
    @AppStorage("dateCompletionStyle") private var dateCompletionStyle: String = "Hollow Circle"

    @AppStorage("habitBarSize") private var habitBarSize: String = "Normal"
    @AppStorage("selectedAppIconIndex") private var selectedIconIndex: Int = 0
    
    @State private var showCheckInMethodsPopup: Bool = false
    @State private var showDateCompletionStylePopup: Bool = false
    @State private var showPremiumUpgrade: Bool = false
    
    @AppStorage("themeChangeCount") private var themeChangeCount: Int = 0
    
    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }

    private var themeColors: [ThemeColorOption] { ThemeColorOption.defaults }

    private var accent: Color { themeManager.primaryColor }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Appearance
                SettingsCard {
                    HStack {
                        HStack(spacing: 0) {
                            Text(LocalizedStringKey("Appearance"))
                            Text("(\(themeManager.appearance.rawValue.capitalized))")
                        }
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                        Spacer()
                        appearanceSegmented
                    }
                }

                // Date Completion Style
                SettingsCard {
                    Button(action: {
                        withAnimation { showDateCompletionStylePopup = true }
                    }) {
                        HStack {
                            Text(LocalizedStringKey("Date Completion Style"))
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(LocalizedStringKey(dateCompletionStyle))
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Habit Bar group
                SettingsCard(spacing: 22) {
//                    NavigationRow(title: "Habit Bar Style", value: "Intuitive")

                    HStack {
                        Text(LocalizedStringKey("Habit Bar size"))
                            .font(.system(size: 16))
                        Spacer()
                        sizeSegmented
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCheckInMethodsPopup = true
                        }
                    }) {
                        NavigationRow(title: "Check-in Methods", value: checkInMethod)
                    }
                    .buttonStyle(.plain)
                }

                // Theme Color
                SettingsCard(alignment: .leading, spacing: 18) {
                    Text("Theme Color")
                        .font(.system(size: 20, weight: .bold))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        ForEach(themeColors.indices, id: \.self) { index in
                            ColorSwatch(
                                colors: themeColors[index].colors,
                                isSelected: themeManager.selectedColorIndex == index
                            )
                            .onTapGesture {
                                if isPremium || themeChangeCount < 2 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        themeManager.selectedColorIndex = index
                                        AnalyticsManager.shared.logThemeChanged()
                                        if !isPremium {
                                            themeChangeCount += 1
                                        }
                                    }
                                } else {
                                    showPremiumUpgrade = true
                                }
                            }
                        }
                    }
                }

                // Icon
                SettingsCard(alignment: .leading, spacing: 18) {
                    Text("Icon")
                        .font(.system(size: 20, weight: .bold))

                    HStack(spacing: 16) {
                        AppIconOption(
                            imageName: "ic_appIcon1",
                            isSelected: selectedIconIndex == 0,
                            accent: accent
                        )
                        .onTapGesture { changeAppIcon(to: 0) }

                        AppIconOption(
                            imageName: "ic_appIcon2",
                            isSelected: selectedIconIndex == 1,
                            accent: accent
                        )
                        .onTapGesture { changeAppIcon(to: 1) }

                        AppIconOption(
                            imageName: "ic_appIcon3",
                            isSelected: selectedIconIndex == 2,
                            accent: accent
                        )
                        .onTapGesture { changeAppIcon(to: 2) }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.pageSurface)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interThemeID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interTheme")
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(themeManager.colorScheme)
        .fullScreenCover(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .overlay {
            if showCheckInMethodsPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showCheckInMethodsPopup = false }
                    }
                
                checkInMethodsPopup
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            if showDateCompletionStylePopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showDateCompletionStylePopup = false }
                    }
                
                dateCompletionStylePopup
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Change App Icon

    private func changeAppIcon(to index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedIconIndex = index
        }

        // Map index to the alternate icon name in the asset catalog
        // Index 0 = AppIcon1, Index 1 = AppIcon2, Index 2 = AppIcon3
        let iconName: String?
        switch index {
        case 0:
            iconName = "AppIcon1"
        case 1:
            iconName = "AppIcon2"
        case 2:
            iconName = "AppIcon3"
        default:
            iconName = nil
        }

        guard UIApplication.shared.alternateIconName != iconName else { return }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Failed to set alternate icon: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Date Completion Style Popup
    
    private var dateCompletionStylePopup: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    withAnimation { showDateCompletionStylePopup = false }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding()
                }
                Spacer()
                Text("Date Completion Style")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            VStack(spacing: 32) {
                // Option 1: Hollow Circle
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Su").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .stroke(accent.opacity(0.8), lineWidth: 1.5)
                                .frame(width: 34, height: 34)
                                .overlay(Text("23").font(.system(size: 15, weight: .medium, design: .rounded)))
                            Image(systemName: "crown")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                                .offset(x: 4, y: -9)
                                .rotationEffect(.degrees(50))
                        }
                    }
                    .frame(width: 50)
                    
                    Text("Hollow Circle")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Spacer()
                    if dateCompletionStyle == "Hollow Circle" {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation { dateCompletionStyle = "Hollow Circle" }
                }
                
                // Option 2: Solid Circle
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Su").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(accent.opacity(0.9))
                                .frame(width: 34, height: 34)
                                .overlay(Text("23").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white))
                            Image(systemName: "crown")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                                .offset(x: 4, y: -8)
                                .rotationEffect(.degrees(50))
                        }
                    }
                    .frame(width: 50)
                    
                    Text("Solid Circle")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Spacer()
                    if dateCompletionStyle == "Solid Circle" {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation { dateCompletionStyle = "Solid Circle" }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(.regularMaterial)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.12), radius: 25, y: 15)
        .padding(.horizontal, 24)
    }

    // MARK: - Check-in Methods Popup
    private var checkInMethodsPopup: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button(action: { withAnimation { showCheckInMethodsPopup = false } }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("Check-in Methods")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Color.clear.frame(width: 20, height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // Option 1: Swipe
            VStack(spacing: 16) {
                // Mini card UI for Swipe
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.1))
                    RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.5)).frame(width: 140) // progress
                    HStack {
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yoga").font(.system(size: 16, weight: .semibold))
                            Text("You can do it!").font(.system(size: 11)).foregroundColor(Color.primary.opacity(0.7))
                        }
                        Spacer()
                        Text("30/60 min").font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    
                    // Swipe hand icon overlay
                    LottieView(animation: .named("swipe-right"))
                        .configure { lottieView in
                            lottieView.contentMode = .scaleAspectFit
                        }
                        .playing(loopMode: .loop)
                        .resizable()
                        .allowsHitTesting(false)
                        .frame(width: 50, height: 50)
                        .offset(x: 120, y: 10)
                }
                .frame(height: 70)
                .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Circle()
                        .strokeBorder(checkInMethod == "Swipe right to check in" ? accent : Color.secondary.opacity(0.3), lineWidth: 2)
                        .background(Circle().fill(checkInMethod == "Swipe right to check in" ? accent : Color.clear))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(checkInMethod == "Swipe right to check in" ? 1 : 0)
                        )
                    Text("Swipe right to check in")
                        .font(.system(size: 16, weight: .medium))
                }
                .onTapGesture {
                    withAnimation { checkInMethod = "Swipe right to check in" }
                }
            }
            
            // Option 2: Tap
            VStack(spacing: 16) {
                // Mini card UI for Tap
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.5))
                    HStack {
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Yoga").font(.system(size: 16, weight: .semibold))
                            Text("30/60 min").font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.4)))
                        }
                        Spacer()
                        Circle().fill(Color.white.opacity(0.3)).frame(width: 28, height: 28)
                            .overlay(Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                            .overlay(
                                LottieView(animation: .named("double-tap-click"))
                                    .configure { lottieView in
                                        lottieView.contentMode = .scaleAspectFit
                                    }
                                    .playing(loopMode: .loop)
                                    .resizable()
                                    .allowsHitTesting(false)
                                    .frame(width: 45, height: 45)
                                    .offset(y: 13)
                            )
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 70)
                .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Circle()
                        .strokeBorder(checkInMethod == "Tap to check in" ? accent : Color.secondary.opacity(0.3), lineWidth: 2)
                        .background(Circle().fill(checkInMethod == "Tap to check in" ? accent : Color.clear))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(checkInMethod == "Tap to check in" ? 1 : 0)
                        )
                    Text("Tap to check in")
                        .font(.system(size: 16, weight: .medium))
                }
                .onTapGesture {
                    withAnimation { checkInMethod = "Tap to check in" }
                }
            }
            .padding(.bottom, 30)
        }
        .background(RoundedRectangle(cornerRadius: 28).fill(Color.pageSurface))
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interThemeFlag,
                    adKey: "interTheme",
                    adUnitID: RemoteConfigManager.shared.interThemeID
                )
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("Theme")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.pageSurface)
    }

    // MARK: Appearance segmented control

    private var appearanceSegmented: some View {
        HStack(spacing: 0) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Image(systemName: mode.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(themeManager.appearance == mode ? .primary : .secondary)
                    .frame(width: 44, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.appearance == mode ? Color.cardSurface : Color.clear)
                            .shadow(color: .black.opacity(themeManager.appearance == mode ? 0.1 : 0), radius: 2, y: 1)
                    )
                    .onTapGesture { 
                        themeManager.appearance = mode 
                        AnalyticsManager.shared.logThemeChanged()
                    }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemFill)))
    }

    // MARK: Habit bar size segmented control

    private var sizeSegmented: some View {
        HStack(spacing: 0) {
            ForEach(["Normal", "Small"], id: \.self) { option in
                Text(option)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(habitBarSize == option ? .white : .secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(habitBarSize == option ? accent : Color.clear)
                    )
                    .onTapGesture { habitBarSize = option }
            }
        }
        .background(Capsule().fill(Color(.tertiarySystemFill)))
    }
}

// MARK: - Reusable pieces

private struct SettingsCard<Content: View>: View {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.cardSurface))
    }
}

private struct NavigationRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer()
            Text(LocalizedStringKey(value))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.systemGray3))
        }
    }
}

private struct ColorSwatch: View {
    let colors: [Color]
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 64, height: 64)

            if isSelected {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 2, y: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppIconOption: View {
    let imageName: String
    let isSelected: Bool
    var accent: Color = Color.defaultPrimary

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? accent : Color.clear, lineWidth: 3)
                )

            if isSelected {
                ZStack {
                    Circle()
                        .fill(accent)
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 4, y: 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemeSettingsView()
            .environmentObject(AppThemeManager())
    }
}
