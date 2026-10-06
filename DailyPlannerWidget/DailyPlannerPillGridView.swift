//
//  DailyPlannerPillGridView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 28/07/26.
//

import SwiftUI
import WidgetKit

// MARK: - Medium widget variant: 2-column pill grid (up to 6 habits)
struct DailyPlannerPillGridView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habits = Array(entry.data.habits.prefix(6))

        VStack(spacing: 0) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                ForEach(habits) { habit in
                    HabitPillRow(habit: habit)
                        .frame(height: 36)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(5)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}
