//
//  MoreSettingsView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//

import SwiftUI

struct MoreSettingsView: View {
    
    let addedHabits: [HabitSummary]
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lockManager: AppLockManager
    @EnvironmentObject private var badgeManager: BadgeManager
    @EnvironmentObject private var themeManager: AppThemeManager
    
    @AppStorage("safetyLockEnabled") private var safetyLock = false
    @AppStorage("appBadgeEnabled") private var appBadge = false
    @State private var confetti = true
    @State private var sound = true
    @State private var showMood = true
    @AppStorage("homeWeekBar") private var weekBar = 1
    @AppStorage("doneHabitPosition") private var doneHabit = 0
    @AppStorage("appLanguage") private var appLanguage = "English"
    @AppStorage("appleHealthSync") private var appleHealthSync = true
    
    @State private var showHealthInfoAlert = false
    @State private var showResetAlert = false
    @State private var showStatsFixedAlert = false
    
    @AppStorage("savedTasks") private var tasks: [AppHabitTask] = []
    
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            
            VStack(spacing: 20) {
                
                // MARK: First Section
                
                SettingsSection {
                    
                    NavigationLink {
                        AllHabitsView()
                    } label: {
                        SettingsRow(title: "Habit Manager")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        SettingsRow(title: "Theme")
                    }
                    .buttonStyle(.plain)
                    
                }
                
                // MARK: Second Section
                
                SettingsSection {
                    
                    ToggleRow(title: "Apple Health Sync", isOn: $appleHealthSync, showInfo: true) {
                        showHealthInfoAlert = true
                    }
                    
                    NavigationLink {
                        LanguageSelectionView()
                    } label: {
                        SettingsRow(
                            title: "Language",
                            value: LocalizedStringKey(appLanguage)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    ToggleRow(title: "Safety Lock", isOn: $safetyLock)
                        .onChange(of: safetyLock) { newValue in
                            lockManager.isEnabled = newValue
                            if newValue {
                                lockManager.isLocked = true
                            }
                        }
                    
                    NavigationLink {
                        ExportOptionView(habits: addedHabits) { start, end, selected in
                            // handle export
                        }
                    } label: {
                        SettingsRow(title: "Export")
                    }
                    .buttonStyle(.plain)
                }
                
                SettingsSection {
                    
                    SegmentRow(
                        title: "Home Week Bar",
                        left: "Last 7 days",
                        right: "This Week",
                        selection: $weekBar
                    )
                    
                    ToggleRow(title: "App Badge", isOn: $appBadge)
                        .onChange(of: appBadge) { newValue in
                            badgeManager.isEnabled = newValue
                        }
                    
                    SegmentRow(
                        title: "Done Habit Position",
                        left: "Keep",
                        right: "Bottom",
                        selection: $doneHabit
                    )
                }
                
                // MARK: Fifth Section
                
                SettingsSection {
                    NavigationLink {
                        DailyNotificationSettingsView()
                    } label: {
                        SettingsRow(title: "Daily Notification")
                    }
                    .buttonStyle(.plain)
                    ToggleRow(
                        title: "Sound",
                        isOn: $sound
                    )
                }
                
                // MARK: Sixth Section
                
                SettingsSection {
                    
                    ToggleRow(
                        title: "Show Mood in Reports",
                        isOn: $showMood
                    )
                }
                
                // MARK: Bottom Buttons
                
                HStack(spacing: 18) {
                    
                    Button {
                        showResetAlert = true
                    } label: {
                        
                        Text("Reset app")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(themeManager.primaryColor)
                            .cornerRadius(28)
                    }
                    
                    Button {
                        fixStats()
                        showStatsFixedAlert = true
                    } label: {
                        
                        Text("Fix Stats")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.red)
                            .cornerRadius(28)
                    }
                    
                }
                
            }
            .padding()
        }
        .alert("Reset App", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("Are you sure you want to completely reset the app? This will erase all habits, moods, and history. The app will close after resetting.")
        }
        .alert("Stats Fixed", isPresented: $showStatsFixedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All habit streaks have been recalculated successfully.")
        }
        .background(Color.pageSurface)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interMoreSettingID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interMoreSetting")
        }
        .alert("Apple Health Sync", isPresented: $showHealthInfoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("When enabled, DailyPlanner securely reads and writes your habit data (such as steps, calories, and water) to Apple Health to keep your progress in sync.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interMoreSettingFlag,
                    adKey: "interMoreSetting",
                    adUnitID: RemoteConfigManager.shared.interMoreSettingID
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
            
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.pageSurface)
    }

    // MARK: - Helper Methods
    
    private func resetApp() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        let appGroupID = WidgetDataStore.appGroupID
        UserDefaults(suiteName: appGroupID)?.removePersistentDomain(forName: appGroupID)
        HabitHistoryStore.deleteAll()
        MoodStore.deleteAll()
        exit(0)
    }
    
    private func fixStats() {
        let history = HabitHistoryStore.loadAll()
        for i in 0..<tasks.count {
            let title = tasks[i].title
            let habitHistory = history.filter { $0.habitTitle == title }
            
            var tempStreak = 0
            let today = Calendar.current.startOfDay(for: Date())
            var checkDate = today
            
            // If completed today, start counting from today
            if habitHistory.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: checkDate) && $0.value >= tasks[i].goal }) {
                tempStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                // Otherwise start from yesterday
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            }
            
            // Count backwards
            while habitHistory.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: checkDate) && $0.value >= tasks[i].goal }) {
                tempStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            }
            
            tasks[i].streakDays = tempStreak
        }
    }
}

struct SettingsSection<Content: View>: View {
    
    @ViewBuilder var content: Content
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            content
            
        }
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}

struct SettingsRow: View {
    
    var title: LocalizedStringKey
    var value: LocalizedStringKey? = nil
    var showInfo: Bool = false
    
    var body: some View {
        
        HStack {
            
            HStack(spacing: 6) {
                
                Text(title)
                    .font(.system(size: 17))
                
                if showInfo {
                    
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 16))
                }
            }
            
            Spacer()
            
            if let value = value {
                
                Text(value)
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .frame(height: 55)
        .contentShape(Rectangle())
    }
}

struct ToggleRow: View {
    
    var title: LocalizedStringKey
    
    @Binding var isOn: Bool
    
    var showInfo: Bool = false
    var onInfoTapped: (() -> Void)? = nil
    
    @EnvironmentObject private var themeManager: AppThemeManager
    
    var body: some View {
        
        HStack {
            
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17))
                
                if showInfo {
                    Button(action: {
                        onInfoTapped?()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray.opacity(0.8))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(themeManager.primaryColor)
        }
        .padding(.horizontal, 20)
        .frame(height: 55)
    }
}

struct SegmentRow: View {
    
    var title: LocalizedStringKey
    
    var left: LocalizedStringKey
    var right: LocalizedStringKey
    
    @Binding var selection: Int
    
    @EnvironmentObject private var themeManager: AppThemeManager
    
    var body: some View {
        
        HStack {
            
            Text(title)
                .font(.system(size: 17))
            
            Spacer()
            
            Picker("", selection: $selection) {
                
                Text(left).tag(0)
                Text(right).tag(1)
                
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            .tint(themeManager.primaryColor)
        }
        .padding(.horizontal, 20)
        .frame(height: 55)
    }
}

#Preview {
    NavigationStack {
        MoreSettingsView(addedHabits: [])
            .environmentObject(AppLockManager())
            .environmentObject(BadgeManager())
    }
}
