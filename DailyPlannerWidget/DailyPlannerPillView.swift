//
//  DailyPlannerPillView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 28/07/26.
//

import SwiftUI
import WidgetKit

// MARK: - Small widget variant: pill list of top habits (matches reference design)
struct DailyPlannerPillView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habits = Array(entry.data.habits.prefix(3))

        VStack(spacing: 8) {
            ForEach(habits) { habit in
                HabitPillRow(habit: habit)
            }
            Spacer(minLength: 0)
        }
        .padding(0)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}

// MARK: - Single two-tone pill row for one habit (icon + title + subtitle)
struct HabitPillRow: View {
    let habit: HabitSummary

    private var fillFraction: Double {
        habit.isSkipped ? 0 : max(0, min(habit.fraction, 1))
    }

    private var subtitle: String {
        habit.isSkipped ? "Skipped" : "\(Int(fillFraction * 100))%"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(habit.color.opacity(0.25))

                Rectangle()
                    .fill(habit.color.opacity(habit.isSkipped ? 0.25 : 0.95))
                    .frame(width: max(0, geo.size.width * fillFraction))

                HStack(spacing: 8) {
                    Text(habit.emoji)
                        .font(.system(size: min(geo.size.height * 0.45, 18)))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(habit.title)
                            .font(.system(size: min(geo.size.height * 0.32, 13), weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(subtitle)
                            .font(.system(size: min(geo.size.height * 0.26, 11)))
                            .foregroundStyle(.black.opacity(0.75))
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
