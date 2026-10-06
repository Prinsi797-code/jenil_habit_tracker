//
//  OverallView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//
//

import SwiftUI

struct OverallView: View {

    // MARK: - Model

    private struct CalendarDay: Identifiable {
        let id = UUID()
        let date: Date
        let dayNumber: Int
        let isCurrentMonth: Bool
        var progress: CGFloat = 0
        var isToday: Bool = false
        var hasNote: Bool = false
    }

    private struct HabitFilter: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
    }

    private struct DoneEntry: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
        let value: String
    }

    @AppStorage("savedTasks") var tasks: [AppHabitTask] = []
    @AppStorage("dateCompletionStyle") private var dateCompletionStyle: String = "Hollow Circle"

    private var habitFilters: [HabitFilter] {
        tasks.map { HabitFilter(emoji: $0.emoji, name: $0.title) }
    }

    private func progress(for entry: HabitLogEntry) -> Double {
        guard let task = tasks.first(where: { $0.title == entry.habitTitle }), task.goal > 0 else {
            return entry.value > 0 ? 1.0 : 0.0
        }
        return min(entry.value / task.goal, 1.0)
    }

    private var doneToday: [DoneEntry] {
        let history = HabitHistoryStore.loadAll()
        let today = Calendar.current.startOfDay(for: Date())
        var todayEntries = history.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        todayEntries = todayEntries.filter { $0.value > 0 }
        
        if selectedFilter != "All" {
            todayEntries = todayEntries.filter { $0.habitTitle == selectedFilter }
        }
        
        return todayEntries.map { entry in
            let emoji = tasks.first(where: { $0.title == entry.habitTitle })?.emoji ?? "✅"
            return DoneEntry(emoji: emoji, name: entry.habitTitle, value: "\(Int(entry.value)) \(entry.unit)")
        }
    }

    // MARK: - State

    @State private var selectedFilter: String = "All"
    @State private var displayedMonth: Date = Date()
    @State private var showAddHabit: Bool = false
    @State private var showPremiumPaywall: Bool = false
    @State private var showRateAsWeekly: Bool = false
    @State private var showDoneTodayMore: Bool = false
    @State private var showSortSheet: Bool = false

    private var targetTasks: [AppHabitTask] {
        selectedFilter == "All" ? tasks : tasks.filter { $0.title == selectedFilter }
    }

    private var bestStreak: Int {
        targetTasks.map { $0.streakDays }.max() ?? 0
    }

    private var habitsDone: Int {
        let history = HabitHistoryStore.loadAll()
        let today = Calendar.current.startOfDay(for: Date())
        var todayEntries = history.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        if selectedFilter != "All" {
            todayEntries = todayEntries.filter { $0.habitTitle == selectedFilter }
        }
        return todayEntries.filter { progress(for: $0) >= 1.0 }.count
    }

    private var perfectDays: Int {
        let history = HabitHistoryStore.loadAll()
        let titles = Set(targetTasks.map { $0.title })
        let filteredHistory = history.filter { titles.contains($0.habitTitle) }
        let grouped = Dictionary(grouping: filteredHistory, by: { $0.date })
        let taskCount = targetTasks.count
        guard taskCount > 0 else { return 0 }
        return grouped.values.filter { dayEntries in
            dayEntries.filter { progress(for: $0) >= 1.0 }.count >= taskCount
        }.count
    }

    private var dailyAverage: Int {
        let history = HabitHistoryStore.loadAll()
        let titles = Set(targetTasks.map { $0.title })
        let filteredHistory = history.filter { titles.contains($0.habitTitle) }
        let grouped = Dictionary(grouping: filteredHistory, by: { $0.date })
        let totalCompletions = filteredHistory.filter { progress(for: $0) >= 1.0 }.count
        let days = grouped.keys.count
        guard days > 0 else { return 0 }
        return totalCompletions / days
    }

    private var monthlyRatePercent: Double {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth)) ?? Date()
        let endOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? Date()
        return calculateRate(from: startOfMonth, to: endOfMonth)
    }

    private var weeklyRatePercent: Double {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let endOfWeek = cal.date(byAdding: DateComponents(day: 6), to: startOfWeek) ?? Date()
        return calculateRate(from: startOfWeek, to: endOfWeek)
    }

    private func calculateRate(from start: Date, to end: Date) -> Double {
        let cal = Calendar.current
        let titles = Set(targetTasks.map { $0.title })
        let history = HabitHistoryStore.entries(from: start, to: end, titles: titles)
        let activeTaskCount = targetTasks.count
        guard activeTaskCount > 0 else { return 0 }
        let components = cal.dateComponents([.day], from: start, to: end)
        let totalDays = (components.day ?? 0) + 1
        let totalPossible = Double(totalDays * activeTaskCount)
        guard totalPossible > 0 else { return 0 }
        let completed = history.reduce(0.0) { $0 + progress(for: $1) }
        return (completed / totalPossible) * 100.0
    }

    @EnvironmentObject private var themeManager: AppThemeManager
    @EnvironmentObject private var storeManager: StoreManager

    // MARK: - Palette (mirrors ContentView's theme)

    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    private let pageBackground = Color.pageSurface
    private let rowTrack = Color(.secondarySystemBackground)

    private let streakOrange = Color(red: 1.0, green: 0.78, blue: 0.42)
    private var streakOrangeBG: Color { streakOrange.opacity(0.2) }
    private let perfectBlue = Color(red: 0.42, green: 0.62, blue: 0.98)
    private var perfectBlueBG: Color { perfectBlue.opacity(0.2) }
    private let doneGreen = Color(red: 0.30, green: 0.78, blue: 0.55)
    private var doneGreenBG: Color { doneGreen.opacity(0.2) }
    private let avgPurple = Color(red: 0.62, green: 0.48, blue: 0.95)
    private var avgPurpleBG: Color { avgPurple.opacity(0.2) }

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    private var currentRatePercent: Double {
        showRateAsWeekly ? weeklyRatePercent : monthlyRatePercent
    }

    private var currentRateLabel: String {
        showRateAsWeekly ? "Weekly Rate" : "Monthly Rate"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                    filterRow
                    calendarCard
                    rateCard
                    statsGrid
                    doneTodayCard
                }
                .padding(.bottom, 120)
            }
            
            if RemoteConfigManager.shared.bannerOverallFlag == 1 {
                BannerAdView(adUnitID: RemoteConfigManager.shared.bannerOverallID)
                    .frame(height: 50)
                    .padding(.top, 0)
                    .padding(.bottom, 90)
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumUpgradeView()
        }
        .sheet(isPresented: $showAddHabit) {
            NewHabitView { emoji, title, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType in
                let newTask = AppHabitTask(
                    emoji: emoji,
                    title: title,
                    current: 0,
                    goal: goal,
                    unit: unit,
                    streakDays: 0,
                    stepAmount: goal > 100 ? 50 : 1,
                    colorHex: colorHex,
                    endDate: endDate,
                    goalPeriod: goalPeriod,
                    habitType: habitType,
                    taskDays: taskDays,
                    timeRange: timeRange,
                    chartType: chartType
                )
                tasks.append(newTask)
                
                // Request HealthKit permission for this habit's data type
                HealthKitManager.requestPermission(forUnit: unit, title: title)
                
                // Schedule notification
                NotificationManager.shared.scheduleNotification(for: title, identifier: newTask.id.uuidString)
            }
        }
        .sheet(isPresented: $showSortSheet) {
            SortHabitsSheet(tasks: $tasks)
                .presentationDetents([.height(550)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                showSortSheet = true
            }) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(pinkRed))
            }

            Spacer()

            HStack(spacing: 6) {
                Text("All")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                Text("Overall")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
//                Image(systemName: "chevron.down")
//                    .font(.system(size: 13, weight: .bold))
//                    .foregroundColor(inkPrimary)
            }

            Spacer()

            Button(action: {
                if !storeManager.isPremium && tasks.count >= StoreManager.freeHabitLimit {
                    showPremiumPaywall = true
                } else {
                    showAddHabit = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(pinkRed))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Filter row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                filterBadge("All", isSelected: selectedFilter == "All") {
                    selectedFilter = "All"
                }

                ForEach(habitFilters) { habit in
                    Button(action: { selectedFilter = habit.name }) {
                        Text(habit.emoji)
                            .font(.system(size: 26))
                            .opacity(selectedFilter == "All" || selectedFilter == habit.name ? 1 : 0.35)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterBadge(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "seal.fill")
                    .font(.system(size: 34))
                    .foregroundColor(pinkRed)
                Text(text)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Calendar card

    private var calendarCard: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(inkPrimary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(monthTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(inkPrimary)
                        .frame(width: 32, height: 32)
                }
            }

            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                ForEach(monthGrid) { day in
                    calendarCell(day)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .padding(.horizontal, 20)
    }

    private func calendarCell(_ day: CalendarDay) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if day.isToday {
                    Circle()
                        .stroke(pinkRed.opacity(0.2), lineWidth: 2)
                        .background(Circle().fill(pinkRed.opacity(0.15)))
                        .frame(width: 34, height: 34)
                } else {
                    Circle()
                        .stroke(pinkRed.opacity(day.isCurrentMonth ? 0.18 : 0.08), lineWidth: 2)
                        .frame(width: 34, height: 34)
                }

                if day.progress >= 1.0 && dateCompletionStyle == "Solid Circle" {
                    Circle()
                        .fill(pinkRed)
                        .frame(width: 34, height: 34)
                } else if day.progress > 0 {
                    Circle()
                        .trim(from: 0, to: day.progress)
                        .stroke(pinkRed, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 34, height: 34)
                        .rotationEffect(.degrees(-90))
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: 16, weight: day.isToday ? .bold : .medium, design: .rounded))
                    .foregroundColor(day.progress >= 1.0 && dateCompletionStyle == "Solid Circle" ? .white : (day.isToday ? pinkRed : (day.isCurrentMonth ? inkPrimary : inkMuted)))
                    
                if day.progress >= 1.0 {
                    Image(systemName: "crown")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                        .offset(x: 0, y: -22)
                        .rotationEffect(.degrees(50))
                }
            }

            Circle()
                .fill(day.hasNote ? inkPrimary : Color.clear)
                .frame(width: 4, height: 4)
        }
    }

    // MARK: - Rate card

    private var rateCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(pinkRed.opacity(0.18), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: currentRatePercent / 100)
                    .stroke(pinkGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text(String(format: "%.2f%%", currentRatePercent))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .padding(.top, 5)
                    Text(currentRateLabel)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(inkSecondary)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showRateAsWeekly.toggle()
                        }
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(inkSecondary)
                    }
                }
            }
            .frame(width: 180, height: 180)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .padding(.horizontal, 20)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
            statTile(icon: "flame.fill", iconColor: streakOrange, iconBG: streakOrangeBG, value: "\(bestStreak)", unit: "Day", label: "Best Streaks")
            statTile(icon: "calendar.badge.checkmark", iconColor: perfectBlue, iconBG: perfectBlueBG, value: "\(perfectDays)", unit: "Day", label: "Perfect Days")
            statTile(icon: "checkmark.seal.fill", iconColor: doneGreen, iconBG: doneGreenBG, value: "\(habitsDone)", unit: nil, label: "Habits Done")
            statTile(icon: "chart.bar.fill", iconColor: avgPurple, iconBG: avgPurpleBG, value: "\(dailyAverage)", unit: nil, label: "Daily Average")
        }
        .padding(.horizontal, 20)
    }

    private func statTile(icon: String, iconColor: Color, iconBG: Color, value: String, unit: String?, label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 46, height: 46)
                .background(Circle().fill(iconBG))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                if let unit {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(inkSecondary)
                }
            }

            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Done today

    private var doneTodayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Done Today")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                Spacer()
                Button(action: { showDoneTodayMore = true }) {
                    HStack(spacing: 3) {
                        Text("More")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(inkSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(inkSecondary)
                    }
                }
            }

            Divider()

            if doneToday.isEmpty {
                Text("Nothing logged yet today.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(inkSecondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(doneToday) { entry in
                        doneRow(entry)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .padding(.horizontal, 20)
        .fullScreenCover(isPresented: $showDoneTodayMore) {
            DoneTodayMoreView()
        }
    }

    private func doneRow(_ entry: DoneEntry) -> some View {
        HStack {
            HStack(spacing: 8) {
                Text(entry.emoji)
                    .font(.system(size: 18))
                Text(entry.name)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(inkPrimary)
            }

            Spacer()

            Text(entry.value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(rowTrack))
    }

    // MARK: - Month calendar math

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func changeMonth(by delta: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private var monthGrid: [CalendarDay] {
        let cal = Calendar.current
        guard
            let monthRange = cal.range(of: .day, in: .month, for: displayedMonth),
            let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth) // 1 = Sunday ... 7 = Saturday
        let leadingCount = (firstWeekday + 5) % 7 // convert to Monday-start offset
        let daysInMonth = monthRange.count
        
        let history = HabitHistoryStore.loadAll()
        let activeTaskCount = tasks.count

        var days: [CalendarDay] = []

        if leadingCount > 0, let leadStart = cal.date(byAdding: .day, value: -leadingCount, to: firstOfMonth) {
            for i in 0..<leadingCount {
                let date = cal.date(byAdding: .day, value: i, to: leadStart) ?? leadStart
                days.append(CalendarDay(date: date, dayNumber: cal.component(.day, from: date), isCurrentMonth: false))
            }
        }

        for d in 0..<daysInMonth {
            let date = cal.date(byAdding: .day, value: d, to: firstOfMonth) ?? firstOfMonth
            let isToday = cal.isDateInToday(date)
            let isPast = date <= Date()
            
            var progress: CGFloat = 0
            if isPast {
                let dayEntries = history.filter { cal.isDate($0.date, inSameDayAs: date) }
                if selectedFilter == "All" {
                    if activeTaskCount > 0 {
                        var totalFrac: Double = 0
                        for entry in dayEntries {
                            totalFrac += self.progress(for: entry)
                        }
                        progress = CGFloat(totalFrac) / CGFloat(activeTaskCount)
                    }
                } else {
                    if let entry = dayEntries.first(where: { $0.habitTitle == selectedFilter }) {
                        progress = CGFloat(self.progress(for: entry))
                    }
                }
            }

            days.append(
                CalendarDay(
                    date: date,
                    dayNumber: d + 1,
                    isCurrentMonth: true,
                    progress: progress,
                    isToday: isToday,
                    hasNote: isToday
                )
            )
        }

        let totalCells = 42
        var trailOffset = 1
        while days.count < totalCells, let lastDate = days.last?.date {
            let date = cal.date(byAdding: .day, value: trailOffset, to: lastDate) ?? lastDate
            days.append(CalendarDay(date: date, dayNumber: cal.component(.day, from: date), isCurrentMonth: false))
            trailOffset = 1
        }

        return days
    }
}

private struct SortHabitsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Binding var tasks: [AppHabitTask]

    @AppStorage("doneHabitPosition") private var mode: Int = 0
    
    private var activeTasks: [AppHabitTask] {
        tasks.filter { !$0.isHidden }
    }

    var body: some View {
        VStack(spacing: 0) {

            ZStack {
                modeSwitcher
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if mode == 1 {
                HStack {
                    Text("Build")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }

            List {
                ForEach(activeTasks) { habit in
                    HStack(spacing: 14) {
                        Text(habit.emoji)
                            .font(.system(size: 24))
                        Text(habit.title)
                            .font(.system(size: 18))
//                        Spacer()
//                        Image(systemName: "line.3.horizontal")
//                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 6)
                }
                .onMove { indices, newOffset in
                    var newActive = activeTasks
                    newActive.move(fromOffsets: indices, toOffset: newOffset)
                    let hidden = tasks.filter { $0.isHidden }
                    tasks = newActive + hidden
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(colorScheme == .dark ? (Color(hex: "#1A1919") ?? Color.black) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .padding(.horizontal, 20)

            Spacer(minLength: 12)

            VStack(spacing: 8) {
                Text(mode == 0
                     ? "You selected 'Keep' mode, all habits will keep their position regardless of complete status."
                     : "You selected 'Bottom' mode, completed habits will go to bottom of the list.")
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Text("Hold and drag")
                    Image(systemName: "line.3.horizontal")
                    Text("to rearrange habits.")
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(themeManager.primaryColor)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(themeManager.primaryColor.opacity(0.12))
        }
        .background(Color.pageSurface.ignoresSafeArea())
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            switcherSegment(title: "Keep", index: 0)
            switcherSegment(title: "Bottom", index: 1)
        }
        .padding(4)
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule())
        .frame(width: 260)
    }

    private func switcherSegment(title: String, index: Int) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(mode == index ? .white : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                Capsule().fill(mode == index ? themeManager.primaryColor : Color.clear)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { mode = index }
            }
    }
}

#Preview {
    OverallView()
}
