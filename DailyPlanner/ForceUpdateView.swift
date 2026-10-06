//
//  ForceUpdateView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 11/08/26.
//

import SwiftUI
import Combine

struct ForceUpdateView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager
    
    let appStoreVersion: String
    
    private var accent: Color { themeManager.primaryColor }
    private var secondaryAccent: Color { themeManager.secondaryColor }
    private let isForced: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    accent.opacity(0.08),
                    Color.pageSurface,
                    Color.pageSurface
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.15), secondaryAccent.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.25), secondaryAccent.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accent, secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 40)
                
                // Title
                Text(isForced ? "Update Required" : "Update Available")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 12)
                
                // Description
                Text(isForced ? "A new version of the app is available.\nPlease update to continue using the app." : "A new version of the app is available.\nWould you like to update now?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 16)
                
                // Version info
                if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    HStack(spacing: 6) {
                        Text("v\(currentVersion)")
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(accent)
                        
                        Text("v\(appStoreVersion)")
                            .foregroundColor(accent)
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    // Update Button
                    Button(action: openAppStore) {
                        HStack(spacing: 10) {
                            Text("Update Now")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [accent, secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: accent.opacity(0.3), radius: 12, y: 6)
                    }
                    
                    if !isForced {
                        Button(action: { dismiss() }) {
                            Text("Not Now")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, isForced ? 50 : 30)
            }
        }
        .interactiveDismissDisabled(isForced)
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private func openAppStore() {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let url = URL(string: "itms-apps://itunes.apple.com/app/\(bundleId)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Force Update Checker (App Store Version)

final class ForceUpdateChecker: ObservableObject {
    
    @Published var isUpdateRequired = false
    @Published var appStoreVersion = "1.0.1"
    
    /// Checks the App Store for the latest version and compares with the current app version.
    func checkForUpdate() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Force update check failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appInfo = results.first,
                   let storeVersion = appInfo["version"] as? String {
                    
                    DispatchQueue.main.async {
                        self?.appStoreVersion = storeVersion
                        
                        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                            return
                        }
                        
                        // If current version < App Store version → force update
                        if currentVersion.compare(storeVersion, options: .numeric) == .orderedAscending {
                            self?.isUpdateRequired = true
                        }
                    }
                }
            } catch {
                print("Force update JSON parse error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

#Preview {
    ForceUpdateView(appStoreVersion: "1.0.1")
        .environmentObject(AppThemeManager())
}
