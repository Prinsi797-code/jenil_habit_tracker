//
//  NoNetworkView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 11/08/26.
//

import SwiftUI

struct NoNetworkView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    
    private var accent: Color { themeManager.primaryColor }
    private var secondaryAccent: Color { themeManager.secondaryColor }
    
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
                    
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 45))
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
                Text("No Internet Connection")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 12)
                
                // Description
                Text("Please check your network settings and\nmake sure you are connected to the internet.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Open Settings Button
                Button(action: openSettings) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Open Settings")
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
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .interactiveDismissDisabled(true)
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NoNetworkView()
        .environmentObject(AppThemeManager())
}
