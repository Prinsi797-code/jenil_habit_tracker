//
//  DailyPlannerApp.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 23/07/26.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
    FirebaseApp.configure()
    MobileAds.shared.start(completionHandler: nil)
    
    RemoteConfigManager.shared.fetchRemoteConfig { success in
        print("Remote config fetch success: \(success)")
        DispatchQueue.main.async {
            AppOpenAdManager.shared.loadAd()
        }
    }

    return true
  }
}

@main
struct DailyPlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var themeManager = AppThemeManager()
    @StateObject private var lockManager = AppLockManager()
    @StateObject private var badgeManager = BadgeManager()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var forceUpdateChecker = ForceUpdateChecker()
    @StateObject private var networkManager = NetworkManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    private var currentLocale: Locale {
        let identifier: String
        switch appLanguage {
        case "Hindi": identifier = "hi"
        case "Spanish": identifier = "es"
        case "Portuguese": identifier = "pt"
        case "Arabic": identifier = "ar"
        case "French": identifier = "fr"
        case "German": identifier = "de"
        case "Russian": identifier = "ru"
        case "Italian": identifier = "it"
        case "Dutch": identifier = "nl"
        case "Japanese": identifier = "ja"
        case "Korean": identifier = "ko"
        case "Turkish": identifier = "tr"
        default: identifier = "en"
        }
        return Locale(identifier: identifier)
    }

    @State private var backgroundEnterTime: Date? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }

                if lockManager.isLocked {
                    AppLockView(lockManager: lockManager)
                        .transition(.opacity)
                }
            }
            .environmentObject(themeManager)
            .environmentObject(badgeManager)
            .environmentObject(storeManager)
            .preferredColorScheme(themeManager.colorScheme)
            .tint(themeManager.primaryColor)
            .accentColor(themeManager.primaryColor)
            .environmentObject(lockManager)
            .environment(\.locale, currentLocale)
            .environment(\.layoutDirection, appLanguage == "Arabic" ? .rightToLeft : .leftToRight)
            .animation(.easeInOut(duration: 0.2), value: lockManager.isLocked)
            .fullScreenCover(isPresented: $forceUpdateChecker.isUpdateRequired) {
                ForceUpdateView(appStoreVersion: forceUpdateChecker.appStoreVersion)
                    .environmentObject(themeManager)
                    .interactiveDismissDisabled(true)
            }
            /*.fullScreenCover(isPresented: Binding(
                get: { !networkManager.isConnected },
                set: { _ in }
            )) {
                NoNetworkView()
                    .environmentObject(themeManager)
                    .interactiveDismissDisabled(true)
            }
            .onAppear {
                forceUpdateChecker.checkForUpdate()
            }*/
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Re-check force update every time app comes to foreground
                forceUpdateChecker.checkForUpdate()
                
                if let bgTime = backgroundEnterTime {
                    if Date().timeIntervalSince(bgTime) >= 10 {
                        AppOpenAdManager.shared.showAdIfAvailable()
                    }
                }
                backgroundEnterTime = nil
            } else if newPhase == .background {
                lockManager.lockIfNeeded()
                backgroundEnterTime = Date()
            }
        }
    }
}
