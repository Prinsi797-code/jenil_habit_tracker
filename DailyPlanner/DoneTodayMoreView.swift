//
//  DoneTodayMoreView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 01/08/26.
//

import SwiftUI

struct DoneTodayMoreView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("savedTasks") var tasks: [AppHabitTask] = []

    @State private var selectedDate: Date = Date()

    @EnvironmentObject private var themeManager: AppThemeManager

    // MARK: - Palette
    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let pageBackground = Color(.systemGroupedBackground)
    private let rowTrack = Color(.secondarySystemBackground)

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    // MARK: - Date helpers

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - Data

    private func progress(for entry: HabitLogEntry) -> Double {
        guard let task = tasks.first(where: { $0.title == entry.habitTitle }), task.goal > 0 else {
            return entry.value > 0 ? 1.0 : 0.0
        }
        return min(entry.value / task.goal, 1.0)
    }

    private var entriesForSelectedDate: [HabitLogEntry] {
        let history = HabitHistoryStore.loadAll()
        return history
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .filter { $0.value > 0 }
            .sorted { $0.habitTitle < $1.habitTitle }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(inkPrimary)
                        .frame(width: 34, height: 34)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(inkPrimary)
                    }

                    Text(dateString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(inkPrimary)

                    Button(action: {
                        // Don't allow navigating past today
                        if !isToday {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isToday ? inkSecondary.opacity(0.3) : inkPrimary)
                    }
                    .disabled(isToday)
                }

                Spacer()

                // Invisible spacer to balance the X button
                Color.clear
                    .frame(width: 34, height: 34)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Content
            if entriesForSelectedDate.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(entriesForSelectedDate) { entry in
                            habitEntryRow(entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            
            // Native Ad pinned at bottom
            if RemoteConfigManager.shared.nativeDoneTodayFlag == 1 {
                NativeAdContainerView(adUnitID: RemoteConfigManager.shared.nativeDoneTodayID)
            }
        }
        .background(pageBackground.ignoresSafeArea())
    }

    // MARK: - Empty state (clipboard illustration)

    private var emptyState: some View {
        VStack(spacing: 22) {
            ZStack {
                // Background circle
                Circle()
                    .fill(pinkRed.opacity(0.08))
                    .frame(width: 180, height: 180)

                // Decorative elements
                clipboardIllustration
            }

            Text("No habits data")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(inkSecondary)
        }
    }

    private var clipboardIllustration: some View {
        ZStack {
            // Small decorative dots and crosses around the clipboard
            // Top-left cross
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(pinkRed.opacity(0.4))
                .offset(x: -55, y: -40)

            // Top-left dot
            Circle()
                .fill(pinkRed.opacity(0.3))
                .frame(width: 6, height: 6)
                .offset(x: -48, y: -15)

            // Top-right small circle
            Circle()
                .stroke(pinkRed.opacity(0.25), lineWidth: 1)
                .frame(width: 8, height: 8)
                .offset(x: 45, y: -50)

            // Right dot
            Circle()
                .fill(pinkRed.opacity(0.2))
                .frame(width: 5, height: 5)
                .offset(x: 55, y: 10)

            // Bottom-left circle
            Circle()
                .stroke(pinkRed.opacity(0.2), lineWidth: 1)
                .frame(width: 7, height: 7)
                .offset(x: -55, y: 20)

            // Bottom-left cross
            Image(systemName: "plus")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(pinkRed.opacity(0.35))
                .offset(x: -60, y: 50)

            // Clipboard body
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(width: 70, height: 70)
                .shadow(color: pinkRed.opacity(0.1), radius: 8, x: 0, y: 4)

            // Clipboard border (dashed bottom part)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(pinkRed.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .frame(width: 70, height: 70)

            // Clipboard clip at top
            RoundedRectangle(cornerRadius: 3)
                .fill(pinkRed.opacity(0.3))
                .frame(width: 30, height: 10)
                .offset(y: -35)

            // Clipboard clip circle
            Circle()
                .fill(pinkRed.opacity(0.25))
                .frame(width: 8, height: 8)
                .offset(y: -38)

            // Three dots inside clipboard
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(pinkRed.opacity(0.45))
                        .frame(width: 5, height: 5)
                }
            }
            .offset(y: 5)

            // Decorative lines below the clipboard
            RoundedRectangle(cornerRadius: 1)
                .fill(pinkRed.opacity(0.25))
                .frame(width: 90, height: 2)
                .offset(y: 48)

            // Dashed line below
            RoundedRectangle(cornerRadius: 1)
                .stroke(pinkRed.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .frame(width: 75, height: 1)
                .offset(y: 42)

            // Small line accent bottom-right
            RoundedRectangle(cornerRadius: 1)
                .fill(pinkRed.opacity(0.2))
                .frame(width: 45, height: 2)
                .offset(x: 10, y: 55)
        }
    }

    // MARK: - Habit entry row

    private func habitEntryRow(_ entry: HabitLogEntry) -> some View {
        let emoji = tasks.first(where: { $0.title == entry.habitTitle })?.emoji ?? "✅"
        let task = tasks.first(where: { $0.title == entry.habitTitle })
        let fraction = progress(for: entry)
        let accentColor = task?.fillColor ?? pinkRed

        return HStack(spacing: 14) {
            // Emoji
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 42, height: 42)
                .background(
                    Circle().fill(accentColor.opacity(0.12))
                )

            // Title & progress text
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.habitTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(inkPrimary)

                Text("\(Int(entry.value)) / \(Int(task?.goal ?? entry.value)) \(entry.unit)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
            }

            Spacer()

            // Completion badge
            if fraction >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            } else {
                // Percentage
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    DoneTodayMoreView()
}
