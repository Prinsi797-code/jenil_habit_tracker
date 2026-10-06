import SwiftUI
import UserNotifications

struct DailyNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager
    
    @AppStorage("isDailyNotificationEnabled") private var isEnabled: Bool = true
    @AppStorage("dailyMotivationMessage") private var motivationMessage: String = "A nice day has begun. 😁"
    @AppStorage("dailyNotificationTime") private var notificationTime: Double = Date().timeIntervalSince1970
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button {
                    InterstitialAdManager.shared.showAdIfAppropriate(
                        flag: RemoteConfigManager.shared.interNotificationFlag,
                        adKey: "interNotification",
                        adUnitID: RemoteConfigManager.shared.interNotificationID
                    )
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Daily Notification")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Placeholder to balance the layout
                Image(systemName: "chevron.left")
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Daily Notification Toggle
                    HStack {
                        Text("Daily Notification")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $isEnabled)
                            .labelsHidden()
                            .tint(themeManager.primaryColor)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.cardSurface))
                    .cornerRadius(20)
                    .onChange(of: isEnabled) { _ in
                        AnalyticsManager.shared.logNotificationSettingsUpdated()
                    }
                    
                    if isEnabled {
                        // Daily Motivation Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Motivation")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("Enter message", text: $motivationMessage)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.cardSurface))
                        .cornerRadius(20)
                        
                        // Time Picker Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            DatePicker(
                                "Select Time",
                                selection: Binding(
                                    get: { Date(timeIntervalSince1970: notificationTime) },
                                    set: { notificationTime = $0.timeIntervalSince1970 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.cardSurface))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .animation(.easeInOut, value: isEnabled)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interNotificationID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interNotification")
            updateNotification()
        }
        .onChange(of: isEnabled) { _ in updateNotification() }
        .onChange(of: motivationMessage) { _ in updateNotification() }
        .onChange(of: notificationTime) { _ in updateNotification() }
    }
    
    private func updateNotification() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        if isEnabled {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = "Daily Motivation"
                    content.body = motivationMessage.isEmpty ? "A nice day has begun. 😁" : motivationMessage
                    content.sound = .default
                    
                    let date = Date(timeIntervalSince1970: notificationTime)
                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    
                    let request = UNNotificationRequest(identifier: "DailyMotivation", content: content, trigger: trigger)
                    center.add(request)
                }
            }
        }
    }
}

struct DailyNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DailyNotificationSettingsView()
    }
}
