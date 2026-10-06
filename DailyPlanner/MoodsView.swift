//
//  MoodsView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 28/07/26.
//

import SwiftUI
 
struct MoodsView: View {
    @Environment(\.dismiss) private var dismiss
 
    // MARK: - Model
 

 
    // MARK: - Real data source
 
    @State private var allMoodEntries: [MoodEntry] = []
    @State private var moodByDate: [Date: MoodType] = [:]
    @State private var noteByDate: [Date: String] = [:]
 
    private var todayDate: Date {
        Date()
    }
 
    private var mondayCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        return cal
    }
 
    private func normalize(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
 
    // MARK: - Navigation state (each card owns its own mode + offset)
 
    @State private var trendMode: RangeMode = .week
    @State private var trendOffset: Int = 0
 
    @State private var summaryMode: RangeMode = .week
    @State private var summaryOffset: Int = 0
 
    @State private var calendarOffset: Int = 0
    @State private var yearOffset: Int = 0

    // MARK: - Sheet state

    @State private var showAddMood: Bool = false
    @State private var showRecordsList: Bool = false
    @State private var selectedCalendarDate: Date? = nil
    @State private var showCalendarMoodDetail: Bool = false
    @State private var showSettings: Bool = false
    @State private var showPremiumUpgrade: Bool = false
 
    // MARK: - Records (derived from real data, latest 5)
 
    private var records: [MoodRecord] {
        let cal = Calendar.current
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "en_US")
        weekdayFormatter.dateFormat = "EEE"
 
        let sorted = allMoodEntries.sorted { $0.date > $1.date }
        return Array(sorted.prefix(5)).compactMap { entry in
            guard let mood = MoodType(rawValue: entry.moodRawValue.capitalized) else { return nil }
            return MoodRecord(
                day: cal.component(.day, from: entry.date),
                weekday: weekdayFormatter.string(from: entry.date).uppercased(),
                mood: mood,
                note: entry.note
            )
        }
    }
 
    // MARK: - Palette
 
    @EnvironmentObject private var themeManager: AppThemeManager

    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    private let pageBackground = Color.pageSurface
    private let cardBackground = Color.cardSurface
    private var accent: Color { themeManager.primaryColor }
    
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    monthCalendarCard
                    weeklyTrendCard
                    weekMonthSummaryCard
                    yearlyStatusCard
                    MoodRecordsCardView(records: records, showRecordsList: $showRecordsList)
                }
                .padding(.top, 12)
                .padding(.bottom, 90)
                .padding(.horizontal, 20)
            }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interMoodsID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interMoods")
            reloadEntries()
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddMood) {
            MoodCheckInView { mood, reason in
                MoodStore.save(MoodEntry(
                    id: UUID(),
                    date: selectedCalendarDate ?? Date(),
                    moodRawValue: mood.rawValue,
                    note: reason
                ))
                selectedCalendarDate = nil
                reloadEntries()
            }
        }
        .fullScreenCover(isPresented: $showRecordsList) {
            MoodRecordsListView()
                .onDisappear {
                    reloadEntries()
                }
        }
        .sheet(isPresented: $showCalendarMoodDetail) {
            if let date = selectedCalendarDate,
               let entry = allMoodEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
               let kind = moodKindFromRaw(entry.moodRawValue) {
                MoodDetailView(
                    mood: kind,
                    date: entry.date,
                    onSave: { note in
                        MoodStore.save(MoodEntry(
                            id: entry.id,
                            date: entry.date,
                            moodRawValue: entry.moodRawValue,
                            note: note
                        ))
                        reloadEntries()
                    },
                    onCancel: {}
                )
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            MoodSettingsView()
        }
        .fullScreenCover(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }

    private func reloadEntries() {
        let entries = MoodStore.loadAll()
        allMoodEntries = entries
        
        var mDict: [Date: MoodType] = [:]
        var nDict: [Date: String] = [:]
        for entry in entries {
            let norm = normalize(entry.date)
            if let type = MoodType(rawValue: entry.moodRawValue.capitalized) {
                mDict[norm] = type
            }
            if !entry.note.isEmpty {
                nDict[norm] = entry.note
            }
        }
        moodByDate = mDict
        noteByDate = nDict
    }

    private func moodKindFromRaw(_ raw: String) -> MoodKind? {
        MoodKind.allCases.first { $0.rawValue == raw || $0.label == raw.capitalized }
    }
 
    // MARK: - Top bar
 
    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interMoodsFlag,
                    adKey: "interMoods",
                    adUnitID: RemoteConfigManager.shared.interMoodsID
                )
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
 
            Spacer(minLength: 8)
 
            Text("Moods")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
 
            Spacer(minLength: 8)
 
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(cardBackground.ignoresSafeArea(edges: .top))
    }
 
    // MARK: - Nav arrow helper (consistent 44x44 tap target, real 32x32 hit area)
 
    private func navArrow(_ system: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(inkSecondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
    }
 
    // MARK: - Week/Month toggle + date-range header (shared by trend & donut cards)
 
    private func weekMonthToggle(mode: Binding<RangeMode>, offset: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            ForEach(RangeMode.allCases, id: \.self) { option in
                Text(option.label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(mode.wrappedValue == option ? .white : inkSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(mode.wrappedValue == option ? accent : Color.clear)
                    )
                    .contentShape(Capsule())
                    .onTapGesture {
                        guard mode.wrappedValue != option else { return }
                        mode.wrappedValue = option
                        offset.wrappedValue = 0
                    }
            }
        }
        .background(Capsule().fill(Color(.tertiarySystemFill)))
    }
 
    private func dateRangeNav(mode: Binding<RangeMode>, offset: Binding<Int>) -> some View {
        HStack(spacing: 2) {
            navArrow("chevron.left") { offset.wrappedValue -= 1 }
            Text(rangeLabel(mode: mode.wrappedValue, offset: offset.wrappedValue))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            navArrow("chevron.right") { offset.wrappedValue += 1 }
        }
    }
 
    // MARK: - Date range math
 
    private func weekStart(offset: Int) -> Date {
        let comps = mondayCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: todayDate)
        guard let currentWeekStart = mondayCalendar.date(from: comps) else { return todayDate }
        return mondayCalendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) ?? currentWeekStart
    }
 
    private func monthStart(offset: Int) -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: todayDate)
        guard let currentMonthStart = Calendar.current.date(from: comps) else { return todayDate }
        return Calendar.current.date(byAdding: .month, value: offset, to: currentMonthStart) ?? currentMonthStart
    }
 
    private func weekRange(offset: Int) -> ClosedRange<Date> {
        let start = normalize(weekStart(offset: offset))
        let end = mondayCalendar.date(byAdding: .day, value: 6, to: start) ?? start
        return start...end
    }
 
    private func monthRange(offset: Int) -> ClosedRange<Date> {
        let start = normalize(monthStart(offset: offset))
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: start)?.count ?? 30
        let end = Calendar.current.date(byAdding: .day, value: daysInMonth - 1, to: start) ?? start
        return start...end
    }
 
    private func range(for mode: RangeMode, offset: Int) -> ClosedRange<Date> {
        mode == .week ? weekRange(offset: offset) : monthRange(offset: offset)
    }
 
    private func weekRangeLabel(offset: Int) -> String {
        let start = normalize(weekStart(offset: offset))
        let end = mondayCalendar.date(byAdding: .day, value: 6, to: start) ?? start
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return "\(f.string(from: start))–\(f.string(from: end))"
    }
 
    private func monthRangeLabel(offset: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM yyyy"
        return f.string(from: monthStart(offset: offset))
    }
 
    private func rangeLabel(mode: RangeMode, offset: Int) -> String {
        mode == .week ? weekRangeLabel(offset: offset) : monthRangeLabel(offset: offset)
    }
 
    // MARK: - Month calendar card
 
    private var monthCalendarCard: some View {
        let days = calendarGrid(offset: calendarOffset)
        let rows = days.chunked(into: 7)
 
        return card {
            HStack {
                navArrow("chevron.left") { calendarOffset -= 1 }
                Spacer(minLength: 8)
                Text(monthRangeLabel(offset: calendarOffset))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                navArrow("chevron.right") { calendarOffset += 1 }
            }
            .padding(.bottom, 8)
 
            HStack(spacing: 0) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(inkPrimary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)
 
            VStack(spacing: 4) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(week) { day in
                            calendarCell(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
 
    private func calendarCell(_ day: CalendarDay) -> some View {
        ZStack {
            if let mood = day.mood {
                Image(mood.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
            } else {
                Text("\(day.dayNumber)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(day.isCurrentMonth ? inkPrimary : inkMuted)
            }
 
            if day.isToday {
                VStack {
                    Spacer()
                    Circle()
                        .fill(inkPrimary)
                        .frame(width: 4, height: 4)
                }
                .frame(height: 38)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: 38)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            guard day.isCurrentMonth else { return }
            let start = normalize(monthStart(offset: calendarOffset))
            guard let tappedDate = mondayCalendar.date(byAdding: .day, value: day.dayNumber - 1, to: start) else { return }
            let normalizedTapped = normalize(tappedDate)
            selectedCalendarDate = normalizedTapped
            if day.mood != nil {
                showCalendarMoodDetail = true
            } else {
                if Calendar.current.isDateInToday(normalizedTapped) {
                    showAddMood = true
                }
            }
        }
    }
 
    private func calendarGrid(offset: Int) -> [CalendarDay] {
        let start = normalize(monthStart(offset: offset))
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: start)?.count ?? 30
 
        // Monday-indexed weekday of the 1st (0 = Mon ... 6 = Sun)
        let systemWeekday = mondayCalendar.component(.weekday, from: start) // 1=Sun...7=Sat
        let mondayIndex = (systemWeekday + 5) % 7
 
        var days: [CalendarDay] = []
 
        if mondayIndex > 0 {
            for offsetBack in stride(from: mondayIndex, through: 1, by: -1) {
                if let date = mondayCalendar.date(byAdding: .day, value: -offsetBack, to: start) {
                    days.append(
                        CalendarDay(
                            dayNumber: mondayCalendar.component(.day, from: date),
                            isCurrentMonth: false,
                            mood: nil,
                            hasNote: false,
                            isToday: false
                        )
                    )
                }
            }
        }
 
        let today = normalize(todayDate)
        for dayNum in 1...daysInMonth {
            guard let date = mondayCalendar.date(byAdding: .day, value: dayNum - 1, to: start) else { continue }
            let key = normalize(date)
            days.append(
                CalendarDay(
                    dayNumber: dayNum,
                    isCurrentMonth: true,
                    mood: moodByDate[key],
                    hasNote: noteByDate[key] != nil,
                    isToday: key == today
                )
            )
        }
 
        let remainder = days.count % 7
        if remainder != 0 {
            let trailingCount = 7 - remainder
            for i in 0..<trailingCount {
                if let date = mondayCalendar.date(byAdding: .day, value: daysInMonth + i, to: start) {
                    days.append(
                        CalendarDay(
                            dayNumber: mondayCalendar.component(.day, from: date),
                            isCurrentMonth: false,
                            mood: nil,
                            hasNote: false,
                            isToday: false
                        )
                    )
                }
            }
        }
 
        return days
    }
 
    // MARK: - Weekly / monthly trend card (line chart connecting mood over time)
 
    private var weeklyTrendCard: some View {
        let points = trendPoints(mode: trendMode, offset: trendOffset)
        let labels = trendLabels(mode: trendMode, offset: trendOffset)
 
        return card {
            HStack {
                weekMonthToggle(mode: $trendMode, offset: $trendOffset)
                    .layoutPriority(0)
                    .fixedSize()               // keep its own natural size...
                Spacer(minLength: 4)           // ...but let the spacer shrink to 4pt first
                dateRangeNav(mode: $trendMode, offset: $trendOffset)
            }
            .padding(.bottom, 14)
 
            ZStack {
                if points.isEmpty {
                    emptyState(height: 160)
                } else {
                    weeklyTrendChart(points: points, labels: labels)
                        .frame(height: 160)
                }
            }
            .overlay(premiumLockOverlay)
        }
    }
 
    private func trendPoints(mode: RangeMode, offset: Int) -> [TrendPoint] {
        switch mode {
        case .week:
            let start = normalize(weekStart(offset: offset))
            var points: [TrendPoint] = []
            for i in 0..<7 {
                guard let date = mondayCalendar.date(byAdding: .day, value: i, to: start) else { continue }
                if let mood = moodByDate[normalize(date)] {
                    points.append(TrendPoint(slotIndex: i, mood: mood))
                }
            }
            return points
 
        case .month:
            let start = normalize(monthStart(offset: offset))
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: start)?.count ?? 30
            var buckets: [Int: [MoodType]] = [:]
            for day in 1...daysInMonth {
                guard let date = mondayCalendar.date(byAdding: .day, value: day - 1, to: start) else { continue }
                if let mood = moodByDate[normalize(date)] {
                    buckets[(day - 1) / 7, default: []].append(mood)
                }
            }
            return buckets.keys.sorted().map { idx in
                let moods = buckets[idx]!
                let avgRank = moods.map { $0.rank }.reduce(0, +) / Double(moods.count)
                let nearest = MoodType.allCases.min(by: { abs($0.rank - avgRank) < abs($1.rank - avgRank) }) ?? .neutral
                return TrendPoint(slotIndex: idx, mood: nearest)
            }
        }
    }
 
    private func trendLabels(mode: RangeMode, offset: Int) -> [String] {
        switch mode {
        case .week:
            return ["M", "T", "W", "T", "F", "S", "S"]
        case .month:
            let start = normalize(monthStart(offset: offset))
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: start)?.count ?? 28
            let weekCount = Int(ceil(Double(daysInMonth) / 7.0))
            return (1...max(weekCount, 1)).map { "W\($0)" }
        }
    }
 
    private func weeklyTrendChart(points: [TrendPoint], labels: [String]) -> some View {
        GeometryReader { geo in
 
            let labelRowHeight: CGFloat = 24
            let topPadding: CGFloat = 22
            let bottomPadding: CGFloat = 22
            // Horizontal insets must be at least half the mood-icon width so
            // the first/last plotted points don't bleed past the chart edge.
            let iconSize: CGFloat = 34
            let cornerClearance: CGFloat = 18
            let sidePadding: CGFloat = max(iconSize / 2 + cornerClearance, 30)
 
            let plotHeight = geo.size.height - labelRowHeight
            let availableHeight = plotHeight - topPadding - bottomPadding
 
            let maxRank: Double = 6
            let slots = max(labels.count - 1, 1)
            let stepX = (geo.size.width - sidePadding * 2) / CGFloat(slots)
 
            ZStack(alignment: .topLeading) {
 
                Path { path in
                    for (index, point) in points.enumerated() {
                        let x = sidePadding + CGFloat(point.slotIndex) * stepX
                        let y = topPadding + availableHeight * CGFloat((maxRank - point.mood.rank) / maxRank)
 
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(.gray.opacity(0.35), lineWidth: 2)
 
                ForEach(points) { point in
                    let x = sidePadding + CGFloat(point.slotIndex) * stepX
                    let y = topPadding + availableHeight * CGFloat((maxRank - point.mood.rank) / maxRank)
 
                    Image(point.mood.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .position(x: x, y: y)
                }
 
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(.gray)
                .frame(width: geo.size.width - sidePadding * 2, height: labelRowHeight)
                .position(x: geo.size.width / 2,
                          y: geo.size.height - labelRowHeight / 2)
            }
        }
    }
 
    // MARK: - Week/Month summary card (donut chart)
 
    private var weekMonthSummaryCard: some View {
        let selectedRange = range(for: summaryMode, offset: summaryOffset)
        let counts = moodCounts(in: selectedRange)
        let total = totalDays(in: selectedRange)
 
        return card {
            HStack {
                weekMonthToggle(mode: $summaryMode, offset: $summaryOffset)
                    .layoutPriority(0)
                    .fixedSize()
                Spacer(minLength: 8)
                dateRangeNav(mode: $summaryMode, offset: $summaryOffset)
            }
            .padding(.bottom, 14)
 
            ZStack {
                if total == 0 {
                    emptyState(height: 180)
                } else {
                    GeometryReader { geo in
                        let chartSize = min(max(geo.size.width * 0.34, 110), 150)
                        HStack(spacing: 8) {
                            if let first = counts.first {
                                legendItem(first, total: total)
                                    .frame(maxWidth: geo.size.width * 0.26, alignment: .leading)
                            }
    
                            Spacer(minLength: 4)
    
                            donutChart(counts: counts, total: total)
                                .frame(width: chartSize, height: chartSize)
    
                            Spacer(minLength: 4)
    
                            if counts.count > 1 {
                                legendItem(counts[1], total: total)
                                    .frame(maxWidth: geo.size.width * 0.26, alignment: .leading)
                            } else {
                                Color.clear.frame(maxWidth: geo.size.width * 0.26)
                            }
                        }
                        .frame(width: geo.size.width)
                    }
                    .padding(.top, 10)
                    .frame(height: 180)
                }
            }
            .overlay(premiumLockOverlay)
        }
    }
 
    private func donutChart(counts: [(mood: MoodType, days: Int)], total: Int) -> some View {
        ZStack {
            ForEach(Array(donutSegments(counts: counts, total: total).enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(segment.mood.color.opacity(0.35), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            .padding(11)
 
            VStack(spacing: 2) {
                Text("\(total)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("days")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(inkSecondary)
            }
        }
    }
 
    private func donutSegments(counts: [(mood: MoodType, days: Int)], total: Int) -> [(mood: MoodType, start: Double, end: Double)] {
        guard total > 0 else { return [] }
        var segments: [(MoodType, Double, Double)] = []
        var cursor: Double = 0
        for entry in counts {
            let fraction = Double(entry.days) / Double(total)
            segments.append((entry.mood, cursor, cursor + fraction))
            cursor += fraction
        }
        return segments
    }
 
    private func legendItem(_ entry: (mood: MoodType, days: Int), total: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(entry.mood.color)
                    .frame(width: 8, height: 8)
                Text(entry.mood.rawValue)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Text("\(entry.days) days")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("\(Int(round(Double(entry.days) / Double(max(total, 1)) * 100)))%")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(inkSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
 
    // MARK: - Shared range-based data helpers
 
    private func moodEntries(in range: ClosedRange<Date>) -> [(mood: MoodType, date: Date)] {
        moodByDate.compactMap { date, mood in
            range.contains(normalize(date)) ? (mood, date) : nil
        }
    }
 
    private func moodCounts(in range: ClosedRange<Date>) -> [(mood: MoodType, days: Int)] {
        let entries = moodEntries(in: range)
        let grouped = Dictionary(grouping: entries, by: { $0.mood })
        return grouped
            .map { (mood: $0.key, days: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.days != rhs.days { return lhs.days > rhs.days }
                return lhs.mood.rawValue < rhs.mood.rawValue
            }
    }
 
    private func totalDays(in range: ClosedRange<Date>) -> Int {
        moodEntries(in: range).count
    }
 
    private func emptyState(height: CGFloat) -> some View {
        Text("No mood entries logged for this period")
            .font(.system(size: 14, design: .rounded))
            .foregroundColor(inkMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: height)
    }
 
    // MARK: - Yearly status card
 
    private var yearlyStatusCard: some View {
        let currentYear = Calendar.current.component(.year, from: todayDate)
        let selectedYear = currentYear + yearOffset
        let daysInYear = daysInYear(year: selectedYear)

        return card {
            HStack {
                Text("Yearly Status")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                HStack(spacing: 2) {
                    navArrow("chevron.left") { yearOffset -= 1 }
                    Text(verbatim: String(selectedYear))
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(inkSecondary)
                    navArrow("chevron.right") { yearOffset += 1 }
                }
            }
            .padding(.bottom, 8)


            let columns = Array(repeating: GridItem(.flexible(minimum: 4), spacing: 2), count: 31)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<daysInYear, id: \.self) { index in
                    Circle()
                        .fill(colorForYearlyDot(at: index, yearOffset: yearOffset))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 10)

            // Legend
            yearlyLegend
        }
    }


    private var yearlyLegend: some View {
        let legendMoods: [(String, Color)] = [
            ("Excellent", MoodType.excellent.color),
            ("Good", MoodType.good.color),
            ("Neutral", MoodType.neutral.color),
            ("Bad", MoodType.bad.color),
            ("Awful", MoodType.awful.color),
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(legendMoods, id: \.0) { label, color in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(inkSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func daysInYear(year: Int) -> Int {
        guard let janFirst = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1)),
              let range = Calendar.current.range(of: .day, in: .year, for: janFirst) else {
            return 365
        }
        return range.count
    }

    /// Each dot represents a day, starting Jan 1 of the selected year.
    /// Dots light up when that day has a logged mood.
    private func colorForYearlyDot(at index: Int, yearOffset: Int) -> Color {
        let currentYear = Calendar.current.component(.year, from: todayDate)
        let year = currentYear + yearOffset
        guard let janFirst = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1)),
              let date = Calendar.current.date(byAdding: .day, value: index, to: janFirst) else {
            return Color(.systemGray5)
        }
        // Don't color future days
        if date > todayDate {
            return Color(.systemGray5).opacity(0.4)
        }
        if let mood = moodByDate[normalize(date)] {
            return mood.color
        }
        return Color(.systemGray5)
    }
 
    // MARK: - Add button
 
    private var addButton: some View {
        Button(action: {
            selectedCalendarDate = nil
            showAddMood = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(accent))
                .shadow(color: accent.opacity(0.4), radius: 10, x: 0, y: 4)
        }
    }
 
    // MARK: - Premium Lock Overlay

    @ViewBuilder
    private var premiumLockOverlay: some View {
        if !isPremium {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
            }
            .padding(-18) // Expand to fill the card bounds if needed, or just let it overlay exactly the chart area
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture {
                showPremiumUpgrade = true
            }
        }
    }

    // MARK: - Card helper
 
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

 
#Preview {
    MoodsView()
}
