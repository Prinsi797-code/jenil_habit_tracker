//
//  DailyPlannerWeekView.swift
//  DailyPlannerWidgetExtension
//
//  Created by Hevin Technoweb on 28/07/26.
//

import SwiftUI
import WidgetKit

// MARK: - Medium widget variant: weekly M-S grid, one row per habit
struct DailyPlannerWeekView: View {
    let entry: DailyPlannerEntry

    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habits = Array(entry.data.habits.prefix(6)) // fits 6 rows at medium height
        let today = entry.data.weekdayIndex

        GeometryReader { geo in
            let labelWidth: CGFloat = geo.size.width * 0.34
            let dotAreaWidth = geo.size.width - labelWidth
            let colWidth = dotAreaWidth / 7
            let rowHeight = geo.size.height / CGFloat(habits.count + 1)
            let dotSize = min(rowHeight, colWidth) * 0.70

            VStack(spacing: 0) {
                // Header row: day letters, today highlighted
                HStack(spacing: 0) {
                    Spacer().frame(width: labelWidth)
                    ForEach(0..<7, id: \.self) { i in
                        ZStack {
                            Circle()
                                .fill(i == today ? Color.red.opacity(0.85) : theme.fontColor.opacity(0.08))
                            Text(dayLetters[i])
                                .font(.system(size: dotSize * 0.55, weight: .semibold))
                                .foregroundStyle(i == today ? .white : theme.fontColor.opacity(0.6))
                        }
                        .frame(width: colWidth, height: rowHeight)
                        .frame(width: colWidth, height: dotSize)
                    }
                }
                .frame(height: rowHeight)

                // One row per habit
                ForEach(habits) { habit in
                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Text(habit.emoji)
                                .font(.system(size: rowHeight * 0.5))
                            Text(habit.title)
                                .font(.system(size: rowHeight * 0.60, weight: .medium))
                                .foregroundStyle(theme.fontColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer(minLength: 0)
                        }
                        .frame(width: labelWidth, alignment: .leading)

                        ForEach(0..<7, id: \.self) { i in
                            Circle()
                                .fill(habit.weekCompletion[i] ? habit.color : theme.fontColor.opacity(0.1))
                                .frame(width: dotSize, height: dotSize)
                                .frame(width: colWidth, height: rowHeight)
                        }
                    }
                    .frame(height: rowHeight)
                }
            }
        }
        .padding(0)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}
