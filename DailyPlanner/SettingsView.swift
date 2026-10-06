//
//  SettingsView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    

    @State private var showPremiumUpgrade: Bool = false
    @State private var isKeyboardVisible: Bool = false
    
    // MARK: - State
    let addedHabits: [HabitSummary]
    
    // MARK: - Real data
    
    @EnvironmentObject private var themeManager: AppThemeManager
    @State private var showThemeSettings: Bool = false

    // MARK: - Palette (mirrors ContentView's theme)
    
    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    private let pageBackground = Color.pageSurface
    private let avatarRing = Color(red: 1.0, green: 0.80, blue: 0.30)
    
    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ProfileHeaderView(addedHabits: addedHabits)
                    PremiumBannerView(showPremiumUpgrade: $showPremiumUpgrade)
                    MoodsCardView()
                    DailyQuoteCardView()
                    SettingsCardsView(addedHabits: addedHabits)
                    OurAppsCardView()
                }
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
            
            if RemoteConfigManager.shared.bannerSettingFlag == 1 && !isKeyboardVisible {
                BannerAdView(adUnitID: RemoteConfigManager.shared.bannerSettingID)
                    .frame(height: 50)
                    .padding(.top, 0)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.25)) { isKeyboardVisible = true }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.25)) { isKeyboardVisible = false }
            }
        }
    }
    
    // MARK: - Card helper
    
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Week math
}


#Preview {
    NavigationStack {
        SettingsView(addedHabits: [])
    }
}


