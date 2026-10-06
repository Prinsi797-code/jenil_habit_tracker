//
//  HabitTrackerView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 25/07/26.
//
//
//

import SwiftUI
import Charts
 
struct HabitTrackerView: View {
 
    enum Mode: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
 
    @AppStorage("savedTasks") var tasks: [AppHabitTask] = []
    @State private var history: [HabitLogEntry] = []
    
    @State private var mode: Mode = .weekly
 
    @State private var weekOffset: Int = 0
    @State private var monthOffset: Int = 0
    @State private var yearOffset: Int = 0
 
    @State private var showAddHabit = false
    @State private var showPremiumPaywall = false
    @State private var habitToDelete: AppHabitTask?
 
    @EnvironmentObject private var themeManager: AppThemeManager
    @EnvironmentObject private var storeManager: StoreManager

    // MARK: Palette (mirrors ContentView's theme)
 
    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let pageBackground = Color.pageSurface
 
    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }
 
    private let cal = Calendar.current
 
    var body: some View {
        VStack(spacing: 0) {
            header
            modePicker
            dateNavigator
 
            ScrollView {
                VStack(spacing: 16) {

                    
                    switch mode {
                    case .weekly:
                        weeklyCard
                        chartCard(title: "Weekly Overview", points: weeklyChartPoints)
                    case .monthly:
                        monthlyGrid
                        chartCard(title: "Monthly Overview", points: monthlyChartPoints, denseLabels: true)
                    case .yearly:
                        yearlyList
                        chartCard(title: "Yearly Overview", points: yearlyChartPoints)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            
            if RemoteConfigManager.shared.bannerHabitFlag == 1 {
                BannerAdView(adUnitID: RemoteConfigManager.shared.bannerHabitID)
                    .frame(height: 50)
                    .padding(.top, 0)
                    .padding(.bottom, 90)
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .onAppear {
            history = HabitHistoryStore.loadAll()
        }
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumUpgradeView()
        }
        .sheet(isPresented: $showAddHabit) {
            NewHabitView()
                .onDisappear {
                    history = HabitHistoryStore.loadAll()
                }
        }
        .alert(item: $habitToDelete) { habit in
            Alert(
                title: Text("Delete \(habit.title)?"),
                message: Text("This removes the habit and all of its check-ins."),
                primaryButton: .destructive(Text("Delete")) {
                    tasks.removeAll { $0.id == habit.id }
                    NotificationManager.shared.cancelNotification(for: habit.id.uuidString)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helpers
    private func isCompleted(_ task: AppHabitTask, on date: Date) -> Bool {
        let entries = history.filter { cal.isDate($0.date, inSameDayAs: date) && $0.habitTitle == task.title }
        if let entry = entries.first {
            return entry.value >= task.goal && task.goal > 0
        }
        return false
    }

    private func toggle(_ task: AppHabitTask, on date: Date) {
        let currentCompleted = isCompleted(task, on: date)
        let newValue = currentCompleted ? 0.0 : task.goal
        
        HabitHistoryStore.upsert(
            habitTitle: task.title,
            date: date,
            value: newValue,
            unit: task.unit,
            memo: "Toggled from Habit Tracker"
        )
        history = HabitHistoryStore.loadAll()
    }

    private func metPercent(in dates: [Date]) -> Double {
        guard !dates.isEmpty, !tasks.isEmpty else { return 0 }
        var completed = 0
        var total = 0
        for date in dates {
            for task in tasks {
                if isCompleted(task, on: date) { completed += 1 }
                total += 1
            }
        }
        return total > 0 ? (Double(completed) / Double(total)) * 100 : 0
    }

    private func totalDone(in dates: [Date]) -> Int {
        var completed = 0
        for date in dates {
            for task in tasks {
                if isCompleted(task, on: date) { completed += 1 }
            }
        }
        return completed
    }

    private func bestDayLabel(in dates: [Date]) -> String? {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        var bestCount = -1
        var bestDate: Date?
        for date in dates {
            let count = tasks.filter { isCompleted($0, on: date) }.count
            if count > bestCount {
                bestCount = count
                bestDate = date
            }
        }
        return bestDate.map { f.string(from: $0) }
    }

    private func longestStreak(for task: AppHabitTask, in dates: [Date]) -> Int {
        var current = 0
        var maxStreak = 0
        for date in dates.sorted() {
            if isCompleted(task, on: date) {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    private func percent(for task: AppHabitTask, in dates: [Date]) -> Double {
        guard !dates.isEmpty else { return 0 }
        let completed = completedCount(for: task, in: dates)
        return (Double(completed) / Double(dates.count)) * 100
    }

    private func completedCount(for task: AppHabitTask, in dates: [Date]) -> Int {
        dates.filter { isCompleted(task, on: $0) }.count
    }
 
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Habit Tracker")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(inkPrimary)
            Spacer()
            Button {
                if !storeManager.isPremium && tasks.count >= StoreManager.freeHabitLimit {
                    showPremiumPaywall = true
                } else {
                    showAddHabit = true
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(pinkGradient)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
 
    private var modePicker: some View {
        Picker("", selection: $mode) {
            ForEach(Mode.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
 
    // MARK: - Date ranges
    private var currentWeekDates: [Date] {
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today),
              let monday = cal.date(byAdding: .day, value: 7 * weekOffset, to: thisMonday) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }
 
    private var weekRangeLabel: String {
        guard let first = currentWeekDates.first, let last = currentWeekDates.last else { return "" }
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return "\(f.string(from: first)) ~ \(f.string(from: last))"
    }
 
    private var currentMonthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
 
    private var monthDatesElapsed: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: currentMonthDate),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: currentMonthDate)) else { return [] }
        let today = Date()
        let isCurrentMonth = cal.isDate(currentMonthDate, equalTo: today, toGranularity: .month)
        let lastDay = isCurrentMonth ? cal.component(.day, from: today) : range.count
        return (0..<lastDay).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
 
    private var monthAllDates: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: currentMonthDate),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: currentMonthDate)) else { return [] }
        return (0..<range.count).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
 
    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy MMM"
        return f.string(from: currentMonthDate)
    }
 
    private var currentYearDate: Date {
        cal.date(byAdding: .year, value: yearOffset, to: Date()) ?? Date()
    }
 
    private var yearDatesElapsed: [Date] {
        guard let start = cal.date(from: cal.dateComponents([.year], from: currentYearDate)) else { return [] }
        let today = Date()
        let isCurrentYear = cal.component(.year, from: currentYearDate) == cal.component(.year, from: today)
        let end: Date
        if isCurrentYear {
            end = today
        } else if let nextYearStart = cal.date(byAdding: .year, value: 1, to: start),
                  let lastDayOfYear = cal.date(byAdding: .day, value: -1, to: nextYearStart) {
            end = lastDayOfYear
        } else {
            end = today
        }
        var dates: [Date] = []
        var d = start
        while d <= end {
            dates.append(d)
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return dates
    }
 
    private var yearLabel: String {
        String(cal.component(.year, from: currentYearDate))
    }
 
    private var dateNavigator: some View {
        HStack {
            Button { withAnimation { shiftPeriod(-1) } } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .foregroundColor(pinkRed)
            }
            Spacer()
            Text(navigatorLabel)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
            Spacer()
            Button { withAnimation { shiftPeriod(1) } } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(pinkRed)
            }
        }
        .font(.system(size: 22))
        .padding(.horizontal, 30)
        .padding(.bottom, 10)
    }
 
    private var navigatorLabel: String {
        switch mode {
        case .weekly: return weekRangeLabel
        case .monthly: return monthLabel
        case .yearly: return yearLabel
        }
    }
 
    private func shiftPeriod(_ delta: Int) {
        switch mode {
        case .weekly: weekOffset += delta
        case .monthly: monthOffset += delta
        case .yearly: yearOffset += delta
        }
    }
 
    // MARK: - Weekly
 
    private var weeklyCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("").frame(width: 96, alignment: .leading)
                ForEach(currentWeekDates, id: \.self) { date in
                    Text(shortWeekday(date))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(inkSecondary)
                        .frame(maxWidth: .infinity)
                }
                Text("").frame(width: 30)
            }
            .padding(.vertical, 8)
 
            ForEach(tasks) { habit in
                habitWeekRow(habit)
                if habit.id != tasks.last?.id {
                    Divider().padding(.leading, 96)
                }
            }
 
            if tasks.isEmpty {
                emptyState
            }
 
            Divider().padding(.top, 10)
            weeklyStatsFooter
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.cardSurface))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
 
    private func shortWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: date).uppercased()
    }
 
    /// Distinct label for chart x-axes. Unlike `shortWeekday` (a single letter, fine for
    /// a fixed-position table column but ambiguous as a category — Tue/Thu both read "T"),
    /// this is guaranteed unique across a week so Swift Charts never merges two days' bars.
    private func chartWeekdayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
 
    private func habitWeekRow(_ habit: AppHabitTask) -> some View {
        let dates = currentWeekDates
        let allDone = !dates.isEmpty && dates.allSatisfy { isCompleted(habit, on: $0) }
 
        return HStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(habit.emoji)
                Text(habit.title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 96, alignment: .leading)
 
            ForEach(dates, id: \.self) { date in
                let done = isCompleted(habit, on: date)
                let isFuture = date > Date() && !cal.isDateInToday(date)
                RoundedRectangle(cornerRadius: 8)
                    .fill(done ? habit.fillColor : habit.fillColor.opacity(0.16))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Group {
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .opacity(isFuture ? 0.35 : 1)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        guard !isFuture else { return }
//                        withAnimation(.easeInOut(duration: 0.12)) {
//                            toggle(habit, on: date)
//                        }
//                    }
            }
 
            ZStack {
                if allDone {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(pinkRed)
                        .font(.system(size: 15))
                }
            }
            .frame(width: 30)
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button(role: .destructive) {
                habitToDelete = habit
            } label: {
                Label("Delete Habit", systemImage: "trash")
            }
        }
    }
 
    private var weeklyStatsFooter: some View {
        let dates = currentWeekDates
        let met = metPercent(in: dates)
        let bestDay = bestDayLabel(in: dates) ?? "-"
        let total = totalDone(in: dates)
        let bestStreak = tasks.map { longestStreak(for: $0, in: dates) }.max() ?? 0
 
        return HStack(spacing: 0) {
            statBlock(value: String(format: "%.0f%%", met), label: "Met", color: pinkRed)
            statBlock(value: bestDay, label: "Best Day", color: .blue)
            statBlock(value: "\(total)", label: "Total Done", color: .green)
            statBlock(value: "\(bestStreak)d", label: "Best Streak", color: peach)
        }
        .padding(.top, 10)
    }
 
    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }
 
    // MARK: - Monthly
 
    private var monthlyGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(tasks) { habit in
                monthlyHabitCard(habit)
            }
        }
    }
 
    private func monthlyHabitCard(_ habit: AppHabitTask) -> some View {
        let allDates = monthAllDates
        let elapsed = monthDatesElapsed
        let percent = percent(for: habit, in: elapsed)
        let count = completedCount(for: habit, in: elapsed)
        let isPerfect = !elapsed.isEmpty && count == elapsed.count
 
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(habit.emoji)
                Text(habit.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
 
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(allDates, id: \.self) { date in
                    let day = cal.component(.day, from: date)
                    let done = isCompleted(habit, on: date)
                    let isFuture = date > Date() && !cal.isDateInToday(date)
                    Text("\(day)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(done ? .white : inkSecondary)
                        .frame(maxWidth: .infinity, minHeight: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(done ? habit.fillColor : (isFuture ? Color.clear : habit.fillColor.opacity(0.12)))
                        )
                        .opacity(isFuture ? 0.35 : 1)
                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            guard !isFuture else { return }
//                            withAnimation(.easeInOut(duration: 0.12)) {
//                                toggle(habit, on: date)
//                            }
//                        }
                }
            }
 
            HStack(spacing: 10) {
                Label(String(format: "%.0f%%", percent), systemImage: "chart.pie.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(habit.fillColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Label("\(count)d", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(peach)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 0)
            }
 
            if isPerfect {
                Text("PERFECT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(inkSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(inkSecondary.opacity(0.08)))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
 
    // MARK: - Yearly
 
    private var yearlyList: some View {
        VStack(spacing: 16) {
            ForEach(tasks) { habit in
                yearlyHabitCard(habit)
            }
        }
    }
 
    private func yearlyHabitCard(_ habit: AppHabitTask) -> some View {
        let dates = yearDatesElapsed
        let percent = percent(for: habit, in: dates)
        let count = completedCount(for: habit, in: dates)
 
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text(habit.emoji)
                    Text(habit.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(String(format: "%.1f%%", percent))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(habit.fillColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text("\(count)D")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(inkSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
 
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 24), spacing: 3) {
                ForEach(dates, id: \.self) { date in
                    let done = isCompleted(habit, on: date)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(done ? habit.fillColor : habit.fillColor.opacity(0.12))
                        .frame(height: 9)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardSurface))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .clipped()
    }
 
    // MARK: - Empty state
 
    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No habits yet")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
            Text("Tap + to add your first habit")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(inkSecondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
 
    // MARK: - Charts
 
    private struct ChartPoint: Identifiable {
        let id = UUID()
        let label: String
        let sortDate: Date
        let percent: Double
    }
 
    /// % of all habits completed on a given day (0-100).
    private func dayPercent(_ date: Date) -> Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter { isCompleted($0, on: date) }.count
        return Double(done) / Double(tasks.count) * 100
    }
 
    private var weeklyChartPoints: [ChartPoint] {
        currentWeekDates.map { date in
            let isFuture = date > Date() && !cal.isDateInToday(date)
            return ChartPoint(label: chartWeekdayLabel(date), sortDate: date, percent: isFuture ? 0 : dayPercent(date))
        }
    }
 
    private var monthlyChartPoints: [ChartPoint] {
        monthDatesElapsed.map { date in
            ChartPoint(label: "\(cal.component(.day, from: date))", sortDate: date, percent: dayPercent(date))
        }
    }
 
    /// One point per elapsed month in the selected year, averaging that month's daily completion %.
    private var yearlyChartPoints: [ChartPoint] {
        let dates = yearDatesElapsed
        guard !dates.isEmpty else { return [] }
        let grouped = Dictionary(grouping: dates) { cal.component(.month, from: $0) }
        let monthSymbols = DateFormatter().shortMonthSymbols ?? []
        return grouped.keys.sorted().compactMap { month -> ChartPoint? in
            guard let days = grouped[month], !days.isEmpty else { return nil }
            let avg = days.map { dayPercent($0) }.reduce(0, +) / Double(days.count)
            let label = monthSymbols.indices.contains(month - 1) ? monthSymbols[month - 1] : "\(month)"
            return ChartPoint(label: label, sortDate: days.first!, percent: avg)
        }
    }
 
    /// A bar chart card summarizing % of habits completed per day (weekly/monthly) or per month (yearly).
    private func chartCard(title: String, points: [ChartPoint], denseLabels: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
 
            if points.isEmpty || tasks.isEmpty {
                Text("No data yet")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Period", point.label),
                        y: .value("Completion", point.percent)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [pinkRed.opacity(0.28), pinkRed.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
 
                    LineMark(
                        x: .value("Period", point.label),
                        y: .value("Completion", point.percent)
                    )
                    .foregroundStyle(pinkGradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
 
                    if points.count <= 12 {
                        PointMark(
                            x: .value("Period", point.label),
                            y: .value("Completion", point.percent)
                        )
                        .foregroundStyle(Color.white)
                        .symbolSize(50)
 
                        PointMark(
                            x: .value("Period", point.label),
                            y: .value("Completion", point.percent)
                        )
                        .foregroundStyle(pinkRed)
                        .symbolSize(22)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 50, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(inkSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: denseLabels ? .automatic(desiredCount: 6) : .automatic) { _ in
                        AxisValueLabel()
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(inkSecondary)
                    }
                }
                .padding(.top, 10)
                .frame(height: 170)
                .clipped()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.cardSurface))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    HabitTrackerView()
}
