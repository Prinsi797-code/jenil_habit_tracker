//
//  DailyPlannerSmallView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 27/07/26.
//

import SwiftUI
import WidgetKit

// MARK: - A single progress ring with an emoji centered inside it
struct WidgetRing: View {
    let habit: HabitSummary
    var iconScale: CGFloat = 0.4

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(habit.color.opacity(0.22), lineWidth: size * 0.07)

                Circle()
                    .trim(from: 0, to: habit.isSkipped ? 0 : max(habit.fraction, 0.001))
                    .stroke(habit.color, style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(habit.isSkipped ? 0.3 : 1)

                Text(habit.emoji)
                    .font(.system(size: size * iconScale))
                    .opacity(habit.isSkipped ? 0.4 : 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Theme resolution shared by every widget size
struct ResolvedTheme {
    let background: Color?
    let isTransparent: Bool
    let fontColor: Color
    let colorScheme: ColorScheme

    init(_ data: DailyPlannerWidgetData) {
        isTransparent = data.isTransparentBackground
        background = data.backgroundHex.map { Color($0) }
        fontColor = data.fontColorHex.map { Color($0) } ?? .primary
        colorScheme = data.isDarkAppearance ? .dark : .light
    }
}

// MARK: - Small widget: single ring for the day's top (first unfinished) habit
struct DailyPlannerSmallView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habit = entry.data.habits.first { !$0.isSkipped && $0.fraction < 1 } ?? entry.data.habits.first

        ZStack(alignment: .topLeading) {
            if let habit {
                WidgetRing(habit: habit, iconScale: 0.42)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.data.dayLabel)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.fontColor.opacity(0.7))
                Text("\(entry.data.dayNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.fontColor)
            }
            .padding(0)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(entry.data.habits.filter { $0.fraction >= 1 }.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.fontColor.opacity(0.6))
                }
            }
            .padding(0)
        }
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}

// MARK: - Small grid widget: NEW, separate small-size layout showing up to 4 habits
struct DailyPlannerSmallGridView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habits = Array(entry.data.habits.prefix(4))

        VStack(spacing: 0) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(habits) { habit in
                    WidgetRing(habit: habit, iconScale: 0.32)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}

// MARK: - Medium widget: up to 10 habits, 5x2 grid (horizontal layout)

struct DailyPlannerMediumView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habits = Array(entry.data.habits.prefix(10))

        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(habits) { habit in
                    WidgetRing(habit: habit, iconScale: 0.36)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}

// MARK: - Large widget: two-column habit card list (matches reference design)

struct DailyPlannerLargeView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        let theme = ResolvedTheme(entry.data)
        let habits = Array(entry.data.habits.prefix(8)) // 2 cols x 4 rows
        let rows = 4

        GeometryReader { geo in
            let headerHeight: CGFloat = 44
            let gridSpacing: CGFloat = 8
            let vStackSpacing: CGFloat = 10
            let availableForGrid = geo.size.height - headerHeight - vStackSpacing
            let rowHeight = (availableForGrid - CGFloat(rows - 1) * gridSpacing) / CGFloat(rows)

            VStack(alignment: .leading, spacing: vStackSpacing) {
                HStack {
                    DayRing(entry: entry, theme: theme)
                        .frame(width: 36, height: 36)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(entry.data.habits.map(\.streakDays).max() ?? 0)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.fontColor)
                        Text("Current Streak")
                            .font(.system(size: 10))
                            .foregroundStyle(theme.fontColor.opacity(0.6))
                    }
                }
                .frame(height: headerHeight)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: gridSpacing), GridItem(.flexible(), spacing: gridSpacing)],
                    spacing: gridSpacing
                ) {
                    ForEach(habits) { habit in
                        HabitCardRow(habit: habit)
                            .frame(height: max(rowHeight, 0))
                    }
                }
            }
        }
        .padding(14)
        .environment(\.colorScheme, theme.colorScheme)
        .widgetBackground(theme: theme.isTransparent ? Color.clear : theme.background)
    }
}

// MARK: - Small ring shown top-left (day number + overall progress across all habits)

private struct DayRing: View {
    let entry: DailyPlannerEntry
    let theme: ResolvedTheme

    private var overallFraction: Double {
        let habits = entry.data.habits
        guard !habits.isEmpty else { return 0 }
        let total = habits.reduce(0) { $0 + min($1.fraction, 1) }
        return total / Double(habits.count)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.red.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(overallFraction, 0.001))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: -2) {
                Text(entry.data.dayLabel)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.fontColor.opacity(0.7))
                Text("\(entry.data.dayNumber)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.fontColor)
            }
        }
    }
}

// MARK: - Single two-tone progress card for one habit

private struct HabitCardRow: View {
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
                    .fill(habit.color.opacity(0.22))

                Rectangle()
                    .fill(habit.color.opacity(habit.isSkipped ? 0.22 : 0.9))
                    .frame(width: max(0, geo.size.width * fillFraction))

                HStack(spacing: 5) {
                    Text(habit.emoji)
                        .font(.system(size: min(geo.size.height * 0.28, 16)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(.system(size: min(geo.size.height * 0.19, 13), weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text(subtitle)
                            .font(.system(size: min(geo.size.height * 0.16, 11)))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                    }
                    .frame(alignment: .leading)
                    
                    Spacer()
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - containerBackground helper (iOS 17 requires it; falls back gracefully on 16)

extension View {
    func widgetBackground(theme fillColor: Color?) -> some View {
        self.modifier(WidgetBackgroundModifier(fillColor: fillColor))
    }
}

private struct WidgetBackgroundModifier: ViewModifier {
    let fillColor: Color?

    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                fillColor ?? Color(.systemBackground)
            }
        } else {
            content.background(fillColor ?? Color(.systemBackground))
        }
    }
}
