//
//  DailyPlannerCalendarView.swift
//  DailyPlannerWidgetExtension
//
//  Created by Hevin Technoweb on 28/07/26.
//

import SwiftUI
import WidgetKit

// MARK: - Small widget variant: month calendar for a single featured habit
struct DailyPlannerCalendarView: View {
    let entry: DailyPlannerEntry

    private let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Precomputed calendar (kept OUT of body, since body is a @ViewBuilder)

    private var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        return calendar
    }

    private var habit: HabitSummary? {
        entry.data.habits.first
    }

    private var accentColor: Color {
        habit?.color ?? .purple
    }

    private var monthGrid: [MonthDay] {
        let markedDays = Set(habit?.monthCompletionDays ?? [])
        return Self.buildMonthGrid(referenceDate: entry.date, calendar: mondayFirstCalendar, markedDays: markedDays)
    }

    private var todayWeekdayIndex: Int {
        let calendar = mondayFirstCalendar
        return (calendar.component(.weekday, from: entry.date) - calendar.firstWeekday + 7) % 7
    }

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let rows = monthGrid.chunked(into: 7)

        VStack(spacing: 5) {
            // Header: habit icon + title
            HStack(spacing: 4) {
                Text(habit?.emoji ?? "")
                    .font(.system(size: 13))
                Text(habit?.title ?? "Habit")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.fontColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }

            // Weekday header row, today's column highlighted
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(i == todayWeekdayIndex ? accentColor.opacity(0.22) : Color.clear)
                        Text(weekdayLetters[i])
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(theme.fontColor.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity, minHeight: 15)
                }
            }

            // Date grid
            VStack(spacing: 3) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(week) { day in
                            VStack(spacing: 1) {
                                Text("\(day.dayNumber)")
                                    .font(.system(size: 10, weight: day.isToday ? .bold : .regular))
                                    .foregroundStyle(day.isCurrentMonth ? theme.fontColor : theme.fontColor.opacity(0.28))
                                Circle()
                                    .fill(day.hasMark ? accentColor : Color.clear)
                                    .frame(width: 3, height: 3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding(0)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }

    // MARK: - Calendar grid builder

    struct MonthDay: Identifiable {
        let id = UUID()
        let dayNumber: Int
        let isCurrentMonth: Bool
        let isToday: Bool
        let hasMark: Bool
    }

    private static func buildMonthGrid(referenceDate: Date, calendar: Calendar, markedDays: Set<Int>) -> [MonthDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate),
              let monthRange = calendar.range(of: .day, in: .month, for: referenceDate)
        else { return [] }

        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        let today = calendar.component(.day, from: referenceDate)
        let daysInMonth = monthRange.count

        var days: [MonthDay] = []

        if leadingCount > 0,
           let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: referenceDate),
           let prevMonthRange = calendar.range(of: .day, in: .month, for: prevMonthDate) {
            let prevDaysCount = prevMonthRange.count
            for offset in stride(from: leadingCount, to: 0, by: -1) {
                days.append(MonthDay(dayNumber: prevDaysCount - offset + 1, isCurrentMonth: false, isToday: false, hasMark: false))
            }
        }

        for day in 1...daysInMonth {
            days.append(MonthDay(dayNumber: day, isCurrentMonth: true, isToday: day == today, hasMark: markedDays.contains(day)))
        }

        var nextDay = 1
        while days.count % 7 != 0 {
            days.append(MonthDay(dayNumber: nextDay, isCurrentMonth: false, isToday: false, hasMark: false))
            nextDay += 1
        }

        return days
    }
}

