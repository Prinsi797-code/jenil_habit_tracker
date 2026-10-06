//
//  DailyPlannerWidget.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 27/07/26.
//

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Entry view, picks the right layout for the widget's size

struct DailyPlannerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DailyPlannerEntry

    var body: some View {
        switch family {
        case .systemMedium:
            DailyPlannerMediumView(entry: entry)
        case .systemLarge, .systemExtraLarge:
            DailyPlannerLargeView(entry: entry)
        default:
            DailyPlannerSmallView(entry: entry)
        }
    }
}

// MARK: - Widget configuration

struct DailyPlannerWidget: Widget {
    let kind: String = "DailyPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPlannerProvider()) { entry in
            DailyPlannerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner")
        .description("See today's habit rings at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Grid widget (small only): 2x2 ring grid, no text

struct DailyPlannerGridWidgetEntryView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        DailyPlannerSmallGridView(entry: entry)
    }
}

struct DailyPlannerGridWidget: Widget {
    let kind: String = "DailyPlannerGridWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPlannerProvider()) { entry in
            DailyPlannerGridWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner Grid")
        .description("A 2x2 grid of today's habit rings, no text.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyPlannerPillWidgetEntryView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        DailyPlannerPillView(entry: entry)
    }
}

struct DailyPlannerPillWidget: Widget {
    let kind: String = "DailyPlannerPillWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPlannerProvider()) { entry in
            DailyPlannerPillWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner Pills")
        .description("Today's top habits as progress pills.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyPlannerPillGridWidgetEntryView: View {
    let entry: DailyPlannerEntry

    var body: some View {
        DailyPlannerPillGridView(entry: entry)
    }
}

struct DailyPlannerPillGridWidget: Widget {
    let kind: String = "DailyPlannerPillGridWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPlannerProvider()) { entry in
            DailyPlannerPillGridWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner Pill Grid")
        .description("Today's habits as a 2-column pill grid.")
        .supportedFamilies([.systemMedium])
    }
}

struct DailyPlannerWeekWidgetEntryView: View {
    let entry: DailyPlannerEntry
    var body: some View {
        DailyPlannerWeekView(entry: entry)
    }
}

struct DailyPlannerWeekWidget: Widget {
    let kind: String = "DailyPlannerWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPlannerProvider()) { entry in
            DailyPlannerWeekWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner Week")
        .description("This week's habit completion at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct DailyPlannerCalendarWidgetEntryView: View {
    let entry: DailyPlannerEntry
    var body: some View {
        DailyPlannerCalendarView(entry: entry)
    }
}

struct DailyPlannerCalendarWidget: Widget {
    let kind: String = "DailyPlannerCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPlannerProvider()) { entry in
            DailyPlannerCalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner Calendar")
        .description("A monthly view of one habit's completion history.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Bundle (add more widgets here as you build them)

@main
struct DailyPlannerWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyPlannerWidget()
        DailyPlannerGridWidget()
        DailyPlannerPillWidget()
        DailyPlannerPillGridWidget()
        DailyPlannerWeekWidget()
        DailyPlannerCalendarWidget()
        if #available(iOS 16.1, *) {
            DailyPlannerLiveActivity()
        }
    }
}

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct DailyPlannerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyPlannerAttributes.self) { context in
            // Lock screen / banner UI
            VStack {
                Text(context.attributes.name)
                    .font(.headline)
                if let activeTimer = context.state.activeTimerHabit {
                    Text("\(activeTimer) in progress")
                } else {
                    Text("Daily Planner Active")
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    if let activeTimer = context.state.activeTimerHabit {
                        Text(activeTimer)
                            .font(.headline)
                            .foregroundColor(.white)
                    } else {
                        Text("Planner")
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let timerEnd = context.state.timerEndTime {
                        Text(timerEnd, style: .timer)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                    } else {
                        Text("\(context.state.selectedHabits.count) Habits")
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        ForEach(context.state.selectedHabits.prefix(4)) { habit in
                            VStack {
                                Text(habit.emoji)
                                    .font(.title2)
                                ProgressView(value: habit.fraction)
                                    .progressViewStyle(LinearProgressViewStyle(tint: habit.color))
                            }
                        }
                    }
                }
            } compactLeading: {
                if let activeTimer = context.state.activeTimerHabit {
                    Text("⏱️")
                } else {
                    Text("📅")
                }
            } compactTrailing: {
                if let timerEnd = context.state.timerEndTime {
                    Text(timerEnd, style: .timer)
                } else {
                    Text("\(context.state.selectedHabits.count)")
                }
            } minimal: {
                Text("📅")
            }
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    DailyPlannerWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    DailyPlannerWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemLarge) {
    DailyPlannerWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemSmall) {
    DailyPlannerGridWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemSmall) {
    DailyPlannerPillWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    DailyPlannerPillGridWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    DailyPlannerWeekWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemSmall) {
    DailyPlannerCalendarWidget()
} timeline: {
    DailyPlannerEntry(date: .now, data: .placeholder)
}
