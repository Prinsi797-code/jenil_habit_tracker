//
//  NavigationTabBar.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//

import SwiftUI

struct NavigationTabBar: View {

    @Binding var selectedTab: Int

    var onHomeSecondTap: () -> Void = {}

    @EnvironmentObject private var themeManager: AppThemeManager

    var inkPrimary: Color = Color(.label)

    private var pinkRed: Color { themeManager.primaryColor }

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    private let icons: [(name: String, tab: Int)] = [
        ("plus.circle.fill", 0),
        ("list.bullet.rectangle.fill", 1),
        ("clipboard", 3),
        ("gearshape.fill", 4)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(icons, id: \.tab) { icon in
                navIcon(icon.name, tab: icon.tab)
                if icon.tab != icons.last?.tab {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(Color.cardSurface)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }

    private func navIcon(_ systemName: String, tab: Int) -> some View {
        let isSelected = tab == selectedTab

        return Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(isSelected ? AnyShapeStyle(pinkGradient) : AnyShapeStyle(inkPrimary))
            .frame(width: 60, height: 50)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: pinkRed.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if tab == selectedTab {
                    if tab == 0 {
                        onHomeSecondTap()
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
    }
}

#Preview {
    NavigationTabBar(selectedTab: .constant(1))
        .environmentObject(AppThemeManager())
}
