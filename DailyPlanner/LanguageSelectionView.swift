//
//  LanguageSelectionView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//

import SwiftUI

struct LanguageSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager
    
    @AppStorage("appLanguage") private var appLanguage = "English"
    
    private let languages = [
        "English", "Hindi", "Spanish", "Portuguese", "Arabic",
        "French", "German", "Russian", "Italian", "Dutch",
        "Japanese", "Korean", "Turkish"
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                SettingsSection {
                    ForEach(languages, id: \.self) { language in
                        Button {
                            appLanguage = language
                            AnalyticsManager.shared.logLanguageChanged()
                        } label: {
                            HStack {
                                Text(language)
                                    .font(.system(size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if appLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeManager.primaryColor)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 55)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if language != languages.last {
                            Divider()
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.pageSurface)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interLanguageID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interLanguage")
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interLanguageFlag,
                    adKey: "interLanguage",
                    adUnitID: RemoteConfigManager.shared.interLanguageID
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
            
            Text("Language")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.pageSurface)
    }
}

// Reusing SettingsSection from MoreSettingsView if needed, or we can use a custom one here.
// Since SettingsSection is internal to DailyPlanner module, we can just use it directly.

#Preview {
    NavigationStack {
        LanguageSelectionView()
            .environmentObject(AppThemeManager())
    }
}
