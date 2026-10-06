//
//  ContentView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 23/07/26.
//

import SwiftUI
import UIKit



struct ContentView: View {



    // MARK: - Dynamic date helpers
    private static let weeksBefore = 2
    private static let weeksAfter = 2

    private static func generateWeekDays(homeWeekBar: Int) -> [DayItem] {
        let cal = Calendar.current
        let today = Date()
        
        let rangeStart: Date
        if homeWeekBar == 0 {
            rangeStart = cal.date(byAdding: .day, value: -6 - (7 * weeksBefore), to: today) ?? today
        } else {
            let weekday = cal.component(.weekday, from: today)
            let daysFromMonday = (weekday + 5) % 7
            let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
            rangeStart = cal.date(byAdding: .day, value: -7 * weeksBefore, to: thisMonday) ?? thisMonday
        }

        let totalDays = 7 * (weeksBefore + weeksAfter + 1)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "E"

        return (0..<totalDays).map { i in
            let date = cal.date(byAdding: .day, value: i, to: rangeStart) ?? today
            let dayNum = cal.component(.day, from: date)
            let label = formatter.string(from: date).prefix(2).capitalized
            return DayItem(label: String(label), date: dayNum, fullDate: date, progress: 0)
        }
    }

    static func todayIndex(homeWeekBar: Int) -> Int {
        if homeWeekBar == 0 {
            return 7 * weeksBefore + 6
        } else {
            let weekday = Calendar.current.component(.weekday, from: Date())
            let mondayOffset = (weekday + 5) % 7
            return 7 * weeksBefore + mondayOffset
        }
    }

    @AppStorage("homeWeekBar") var homeWeekBar = 1

    @State var days: [DayItem] = ContentView.generateWeekDays(homeWeekBar: UserDefaults.standard.object(forKey: "homeWeekBar") as? Int ?? 1)

    // Index of the currently selected day in `days` (defaults to today)
    @State private var selectedDayIndex: Int = ContentView.todayIndex(homeWeekBar: UserDefaults.standard.object(forKey: "homeWeekBar") as? Int ?? 1)

    // Index of the currently visible week "page" in the paged day strip
    @State private var selectedWeekIndex: Int = ContentView.todayIndex(homeWeekBar: UserDefaults.standard.object(forKey: "homeWeekBar") as? Int ?? 1) / 7

    @State private var selectedTab: Int = 0
    @State private var showNewHabit: Bool = false
    @State private var showPremiumPaywall: Bool = false
    @State private var showCheckInOnboarding: Bool = false
    @AppStorage("hasSeenCheckInMethodOnboarding") private var hasSeenCheckInOnboarding: Bool = false

    @AppStorage("hasSeenAddHabitTooltip") private var hasSeenAddHabitTooltip: Bool = false
    @State private var showAddHabitTooltip: Bool = false

    @State private var showFilterPopup: Bool = false
    @State private var selectedStatus: String = "All"
    @State private var selectedTime: String = "All"

    // Floating corner button state (lightbulb + smiley/add)
    @State private var showTipsPopup: Bool = false
    @State private var showAddMoodPopup: Bool = false
    @State private var todayMoodLogged: Bool = false

    private let statusOptions = ["All", "Unmet", "Met"]
    private let timeOptions = ["All", "Now", "Anytime", "Morning", "Afternoon", "Evening"]

    // MARK: - Dynamic task list
    @AppStorage("savedTasks") var tasks: [AppHabitTask] = []
    
    @AppStorage("doneHabitPosition") private var doneHabitPosition: Int = 0
    @AppStorage("dateCompletionStyle") private var dateCompletionStyle: String = "Hollow Circle"

    // MARK: - Day-change auto-reset
    @AppStorage("showMoodsHomeFloatingButton") private var showHomeFloatingButton: Bool = true
    @AppStorage("lastActiveDate") private var lastActiveDate: String = ""
    @AppStorage("lastCelebrationDate") private var lastCelebrationDate: String = ""
    @State private var showCelebrationOverlay = false
    @State private var pendingCelebration = false
    @AppStorage("neverShowCelebration") private var neverShowCelebration: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var previousProgress: CGFloat = -1.0

    // Only one row's swipe actions revealed at a time
    @State private var swipedTaskID: UUID? = nil

    // Memo popup state (shown when a task is completed)
    @State private var memoTaskID: UUID? = nil
    @State private var memoDraft: String = ""
    @State private var memoMood: String = "🙂"
    @State private var memoDisabled: Bool = false
    @FocusState private var memoFieldFocused: Bool

    private let moodOptions = ["😀", "🙂", "😐", "☹️", "😭"]

    // MARK: - Task Details navigation
    @State private var selectedDetailTaskID: UUID? = nil
    @State private var taskToEdit: AppHabitTask? = nil
    @State private var isKeyboardVisible: Bool = false

    private var headerTitle: String {
        guard days.indices.contains(selectedDayIndex) else { return "Today" }
        return selectedDayIndex == ContentView.todayIndex(homeWeekBar: homeWeekBar) ? "Today" : days[selectedDayIndex].label
    }

    private var currentDateString: String {
        guard days.indices.contains(selectedDayIndex) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: days[selectedDayIndex].fullDate)
    }

    @EnvironmentObject private var themeManager: AppThemeManager
    @EnvironmentObject private var storeManager: StoreManager

    // MARK: - Palette
    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let cardBlue = Color(red: 0.40, green: 0.49, blue: 0.80)
    private let cardBlueDeep = Color(red: 0.32, green: 0.40, blue: 0.72)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let pageBackground = Color.pageSurface

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    private var blueGradient: LinearGradient {
        LinearGradient(colors: [cardBlue, cardBlueDeep], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {

                    mainContent

                }
                .overlay(alignment: .bottom) {
                    if !isKeyboardVisible {
                        NavigationTabBar(
                            selectedTab: $selectedTab,
                            onHomeSecondTap: {
                                if !storeManager.isPremium && tasks.count >= StoreManager.freeHabitLimit {
                                    showPremiumPaywall = true
                                } else {
                                    showNewHabit = true
                                }
                            },
                            inkPrimary: inkPrimary
                        )
                        .overlay(alignment: .bottomLeading) {
                            if showAddHabitTooltip && selectedTab == 0 {
                                AddHabitTooltipView {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showAddHabitTooltip = false
                                        hasSeenAddHabitTooltip = true
                                    }
                                }
                                .padding(.bottom, 75)
                                .padding(.leading, 10)
                                .padding(.trailing, 40)
                                .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity))
                            }
                        }
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .background(pageBackground.ignoresSafeArea())
                .sheet(isPresented: $showPremiumPaywall) {
                    PremiumUpgradeView()
                }
                .fullScreenCover(isPresented: $showNewHabit) {
                    NewHabitView { emoji, title, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType in
                        let newTask = AppHabitTask(
                            emoji: emoji,
                            title: title,
                            current: 0,
                            goal: goal,
                            unit: unit,
                            streakDays: 0,
                            stepAmount: 1,
                            colorHex: colorHex,
                            endDate: endDate,
                            goalPeriod: goalPeriod,
                            habitType: habitType,
                            taskDays: taskDays,
                            timeRange: timeRange,
                            chartType: chartType
                        )
                        tasks.append(newTask)
                        refreshDayProgress()
                        
                        // Request HealthKit permission for this habit's data type
                        HealthKitManager.requestPermission(forUnit: unit, title: title)
                        
                        // Schedule notification
                        NotificationManager.shared.scheduleNotification(for: title, identifier: newTask.id.uuidString)
                    }
                }

                if showFilterPopup {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showFilterPopup = false
                            }
                        }

                    filterPopup
                        .padding(.horizontal, 16)
                        .padding(.top, 64)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Dim background + memo popup, shown when a task is marked complete
                if memoTaskID != nil {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                        .onTapGesture { dismissMemo(save: false) }
                        .transition(.opacity)

                    VStack {
                        memoPopup
                            .padding(.horizontal, 20)
                            .padding(.top, 150)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating corner buttons (lightbulb + smiley/add), sitting above the tab bar
                if selectedTab == 0 && memoTaskID == nil && !showAddHabitTooltip {
                    VStack {
                        Spacer()
                        HStack {
                            lightbulbButton
                            Spacer()
                            if !todayMoodLogged && showHomeFloatingButton {
                                smileyAddButton
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, (RemoteConfigManager.shared.bannerMainFlag == 1) ? 150 : 90)
                    }
                }
            }
            .onAppear {
                todayMoodLogged = (MoodStore.entryForToday() != nil)
                resetTasksIfDayChanged()
                publishToWidget()
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                    withAnimation(.easeOut(duration: 0.25)) { isKeyboardVisible = true }
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    withAnimation(.easeOut(duration: 0.25)) { isKeyboardVisible = false }
                }
                
                if !hasSeenCheckInOnboarding {
                    showCheckInOnboarding = true
                    hasSeenCheckInOnboarding = true // Mark as seen immediately so it never shows again, even if dismissed
                }
                
                if !hasSeenAddHabitTooltip {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showAddHabitTooltip = true
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    resetTasksIfDayChanged()
                }
            }
            .onChange(of: homeWeekBar) { newValue in
                days = ContentView.generateWeekDays(homeWeekBar: newValue)
                selectedDayIndex = ContentView.todayIndex(homeWeekBar: newValue)
                selectedWeekIndex = selectedDayIndex / 7
                refreshDayProgress()
            }
            .onChange(of: tasks) { _ in
                publishToWidget()
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedDetailTaskID) { id in
                if let task = tasks.first(where: { $0.id == id }) {
                    TaskDetailScreen(task: detailTask(from: task)) { action in
                        handleTaskDetailAction(action, for: id)
                    }
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showCheckInOnboarding) {
                CheckInMethodOnboardingView()
                    .presentationDetents([.fraction(0.80)])
            }
        }
        .overlay {
            if showCelebrationOverlay {
                CelebrationView(isPresented: $showCelebrationOverlay)
                    .transition(.opacity)
            }
            if showTipsPopup {
                TipsPopupOverlay(isPresented: $showTipsPopup)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: memoTaskID)
        .sheet(isPresented: $showAddMoodPopup) {
            MoodCheckInView { mood, reason in
                MoodStore.save(MoodEntry(
                    id: UUID(),
                    date: Date(),
                    moodRawValue: mood.rawValue,
                    note: reason
                ))
                todayMoodLogged = true
                print("Saved mood: \(mood.label), reason: \(reason)")
            }
        }
        .sheet(item: $taskToEdit) { task in
            HabitDetailView(
                emoji: task.emoji,
                name: task.title,
                isCustom: true,
                taskToEdit: task,
                onSave: { emoji, name, goalAmount, goalUnit, colorHex, endDate, goalPeriod, habitType, taskDays, selectedTimeRange, chartType in
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index].emoji = emoji
                        tasks[index].title = name
                        tasks[index].goal = goalAmount
                        tasks[index].unit = goalUnit
                        tasks[index].colorHex = colorHex
                        tasks[index].endDate = endDate
                        tasks[index].goalPeriod = goalPeriod
                        tasks[index].habitType = habitType
                        tasks[index].taskDays = taskDays
                        tasks[index].timeRange = selectedTimeRange
                        tasks[index].chartType = chartType
                    }
                    taskToEdit = nil
                }
            )
        }
    }

    // MARK: - Floating corner buttons

    private var lightbulbButton: some View {
        Button(action: {
            Haptics.impact(.light)
            showTipsPopup = true
        }) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.35))
                    .frame(width: 35, height: 35)
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    private var smileyAddButton: some View {
        Button(action: {
            Haptics.impact(.light)
            showAddMoodPopup = true
        }) {
            Image("ic_moodSelect")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Tab routing

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case 1:
            OverallView()
        case 3:
            HabitTrackerView()
        case 4:
            SettingsView(addedHabits: addedHabits)
        default:
            dailyPlannerContent
        }
    }
    
    private var addedHabits: [HabitSummary] {
        tasks.filter { !$0.isHidden }.map {
            HabitSummary(
                id: $0.id,
                emoji: $0.emoji,
                title: $0.title,
                fraction: Double($0.fraction),
                colorHex: $0.fillColor.toHex(),
                streakDays: $0.streakDays,
                isSkipped: $0.isSkipped
            )
        }
    }

    private var dailyPlannerContent: some View {
        VStack(spacing: 0) {
            topBar
            weekStrip
            tasksList
            
            if RemoteConfigManager.shared.bannerMainFlag == 1 {
                BannerAdView(adUnitID: RemoteConfigManager.shared.bannerMainID)
                    .frame(height: 50)
                    .padding(.top, 0)
                    .padding(.bottom, 90)
            }
        }
        .onAppear {
            refreshDayProgress()
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .animation(.easeInOut(duration: 0.15), value: selectedDayIndex)

                Text(currentDateString)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
            }

            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showFilterPopup.toggle()
                    }
                }) {
                    HStack(spacing: 5) {
                        Text("All")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .rotationEffect(.degrees(showFilterPopup ? 180 : 0))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(pinkGradient))
                    .shadow(color: pinkRed.opacity(0.35), radius: 8, x: 0, y: 4)
                }

                Spacer()

                NavigationLink {
                    MoodsView()
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.45))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        
                        Text("🙂")
                            .font(.system(size: 20))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color(red: 0.85, green: 0.18, blue: 0.22)).frame(width: 15, height: 15))
                            .offset(x: 2, y: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    // MARK: - Week strip (paged: one week visible at a time, swipe to move to next/previous week)

    private var weeks: [[DayItem]] {
        stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private var weekStrip: some View {
        TabView(selection: $selectedWeekIndex) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                HStack(spacing: 14) {
                    ForEach(Array(week.enumerated()), id: \.element.id) { dayInWeek, day in
                        weekStripCell(index: weekIndex * 7 + dayInWeek, day: day)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
                .tag(weekIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 78)
        .padding(.top, 22)
        .onChange(of: selectedDayIndex) { newIndex in
            let newWeek = newIndex / 7
            if newWeek != selectedWeekIndex {
                selectedWeekIndex = newWeek
            }
        }
    }

    private func weekStripCell(index: Int, day: DayItem) -> some View {
        let isSelected = index == selectedDayIndex
        let isToday = index == ContentView.todayIndex(homeWeekBar: homeWeekBar)

        return VStack(spacing: 8) {
            Text(day.label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? inkPrimary : inkSecondary)

            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.cardSurface)
                        .shadow(color: pinkRed.opacity(0.25), radius: 6, x: 0, y: 3)
                        .frame(width: 30, height: 30)
                }

                Circle()
                    .stroke(pinkRed.opacity(0.18), lineWidth: 2.5)
                    .frame(width: 30, height: 30)

                if day.progress >= 1.0 && dateCompletionStyle == "Solid Circle" {
                    Circle()
                        .fill(isSelected ? AnyShapeStyle(pinkGradient) : AnyShapeStyle(pinkRed.opacity(0.55)))
                        .frame(width: 30, height: 30)
                } else if day.progress > 0 {
                    Circle()
                        .trim(from: 0, to: day.progress)
                        .stroke(
                            isSelected ? AnyShapeStyle(pinkGradient) : AnyShapeStyle(pinkRed.opacity(0.55)),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                }

                Text("\(day.date)")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(day.progress >= 1.0 && dateCompletionStyle == "Solid Circle" ? .white : (isSelected ? inkPrimary : inkSecondary))
                    
                if day.progress >= 1.0 {
                    Image(systemName: "crown")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                        .offset(x: 0, y: -19)
                        .rotationEffect(.degrees(50))
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: 34)
        .overlay(
            Capsule()
                .stroke(pinkRed.opacity(0.4), lineWidth: 1.5)
                .padding(.vertical, -1)
                .padding(.horizontal, -4)
                .opacity(isToday ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedDayIndex = index
            }
        }
    }

    // MARK: - Dynamic tasks list (replaces the old single Walk card)
    
    private var sortedTasks: [AppHabitTask] {
        tasks.sorted { task1, task2 in
            if doneHabitPosition == 1 {
                let is1Done = task1.isCompleted
                let is2Done = task2.isCompleted
                if is1Done != is2Done {
                    return !is1Done && is2Done // incomplete tasks (false) come before completed (true)
                }
            }
            
            // Maintain original order for tasks with same completion status
            let idx1 = tasks.firstIndex(where: { $0.id == task1.id }) ?? 0
            let idx2 = tasks.firstIndex(where: { $0.id == task2.id }) ?? 0
            return idx1 < idx2
        }
    }
    
    private func binding(for task: AppHabitTask) -> Binding<AppHabitTask> {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return .constant(task)
        }
        return $tasks[index]
    }

    private var tasksList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(sortedTasks) { task in
                    if !task.isHidden && matchesStatus(task) && matchesDetails(task) {
                        HabitRowView(
                            task: binding(for: task),
                            isSwiped: swipedTaskID == task.id,
                            onSwipeOpen: { swipedTaskID = task.id },
                            onSwipeClose: { if swipedTaskID == task.id { swipedTaskID = nil } },
                            onComplete: { presentMemo(for: task.id) },
                            onAdd: { addProgress(task.id) },
                            onSetProgress: { setProgress(task.id, current: $0) },
                            onSkip: { toggleSkip(task.id) },
                            onHide: { hideTask(task.id) },
                            onReset: { resetTask(task.id) },
                            onOpenDetail: { selectedDetailTaskID = task.id },
                            pinkGradient: pinkGradient,
                            pinkRed: pinkRed,
                            inkPrimary: inkPrimary,
                            inkSecondary: inkSecondary
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tasks)
            .padding(.top, 22)
            .padding(.bottom, 120) // extra padding for floating buttons
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) { swipedTaskID = nil }
            }
        }
    }

    // MARK: - Memo popup
    @ViewBuilder
    private var memoPopup: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                if memoDraft.isEmpty {
                    Text(LocalizedStringKey("Input your memo here"))
                        .foregroundColor(inkSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $memoDraft)
                    .focused($memoFieldFocused)
                    .frame(minHeight: 90, maxHeight: 140)
                    .scrollContentBackground(.hidden)
            }

            HStack(spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(moodOptions, id: \.self) { mood in
                            Text(mood)
                                .font(.system(size: 22))
                                .opacity(memoMood == mood ? 1.0 : 0.45)
                                .scaleEffect(memoMood == mood ? 1.15 : 1.0)
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.15)) { memoMood = mood }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                }

                Spacer(minLength: 8)

                Button(action: { memoDisabled.toggle() }) {
                    Text(LocalizedStringKey("Disable memo"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(memoDisabled ? pinkRed : inkSecondary)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Button(action: { dismissMemo(save: true) }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(pinkGradient))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
        )
        .onAppear {
            memoFieldFocused = true
        }
    }

    // MARK: - Task actions
    private func taskIndex(_ id: UUID) -> Int? {
        tasks.firstIndex(where: { $0.id == id })
    }

    private func refreshDayProgress(isMemoPending: Bool = false) {
        let todayIdx = ContentView.todayIndex(homeWeekBar: homeWeekBar)
        let today = days[todayIdx].fullDate

        // Persist today's snapshot for each visible task so exports can read history later.
        for task in tasks where !task.isHidden {
            let memoCombined = [task.mood, task.memoText.isEmpty ? nil : task.memoText]
                .compactMap { $0 }
                .joined(separator: " ")
            HabitHistoryStore.upsert(
                habitTitle: task.title,
                date: today,
                value: task.current,
                unit: task.unit,
                memo: memoCombined
            )
        }

        let visible = tasks.filter { !$0.isHidden && !$0.isSkipped && matchesDetails($0) }
        guard !visible.isEmpty else {
            days[todayIdx].progress = 0
            return
        }
        let totalFraction = visible.reduce(0.0) { $0 + Double($1.fraction) }
        let newProgress = CGFloat(totalFraction / Double(visible.count))
        days[todayIdx].progress = newProgress
        
        let oldProgress = previousProgress
        previousProgress = newProgress
        
        // Only trigger celebration if old progress was known (>= 0), incomplete (< 1.0), and new is complete (>= 1.0)
        if oldProgress >= 0 && oldProgress < 1.0 && newProgress >= 1.0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.string(from: today)
            
            if lastCelebrationDate != todayString && !neverShowCelebration {
                // Ensure UI updates happen on main thread to avoid warnings, though SwiftUI usually handles it
                DispatchQueue.main.async {
                    self.lastCelebrationDate = todayString
                    if isMemoPending {
                        self.pendingCelebration = true
                    } else {
                        withAnimation {
                            self.showCelebrationOverlay = true
                        }
                    }
                }
            }
        }
    }

    private func presentMemo(for id: UUID) {
        guard let i = taskIndex(id), !tasks[i].isCompleted else { return }
        Haptics.success()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tasks[i].isCompleted = true
            tasks[i].current = tasks[i].goal
            tasks[i].streakDays += 1
            AnalyticsManager.shared.logHabitCompleted()
            swipedTaskID = nil
        }
        refreshDayProgress(isMemoPending: true)

        memoDraft = tasks[i].memoText
        memoMood = tasks[i].mood ?? "🙂"
        memoDisabled = false
        memoTaskID = id
    }

    private func dismissMemo(save: Bool) {
        if save, let id = memoTaskID, let i = taskIndex(id) {
            tasks[i].memoText = memoDisabled ? "" : memoDraft
            tasks[i].mood = memoDisabled ? nil : memoMood
        }
        memoFieldFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            memoTaskID = nil
        }
        memoDraft = ""
        
        if pendingCelebration {
            pendingCelebration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { self.showCelebrationOverlay = true }
            }
        }
    }

    private func addProgress(_ id: UUID) {
        guard let i = taskIndex(id), !tasks[i].isCompleted, !tasks[i].isSkipped else { return }
        Haptics.impact(.light)
        let stepAmount = tasks[i].stepAmount
        withAnimation(.easeOut(duration: 0.2)) {
            tasks[i].current = min(tasks[i].current + stepAmount, tasks[i].goal)
        }
        
        // Save incremental progress to Apple Health
        HealthKitManager.saveData(
            value: stepAmount,
            unit: tasks[i].unit,
            title: tasks[i].title
        )
        
        if tasks[i].current >= tasks[i].goal && !tasks[i].isCompleted {
            presentMemo(for: id)
        } else {
            refreshDayProgress()
        }
    }

    private func setProgress(_ id: UUID, current: Double) {
        guard let i = taskIndex(id), !tasks[i].isCompleted, !tasks[i].isSkipped else { return }
        let clamped = min(max(current, 0), tasks[i].goal)
        let step = max(tasks[i].stepAmount, 0.0001)
        let oldStepIndex = Int(tasks[i].current / step)
        let newStepIndex = Int(clamped / step)
        if newStepIndex != oldStepIndex {
            Haptics.selection()
        }
        tasks[i].current = clamped
        if clamped >= tasks[i].goal {
            presentMemo(for: id)
        } else {
            refreshDayProgress()
        }
    }

    private func toggleSkip(_ id: UUID) {
        guard let i = taskIndex(id) else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            tasks[i].isSkipped.toggle()
            swipedTaskID = nil
        }
        refreshDayProgress()
    }

    private func hideTask(_ id: UUID) {
        guard taskIndex(id) != nil else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            tasks[taskIndex(id)!].isHidden = true
            swipedTaskID = nil
        }
        refreshDayProgress()
    }
    
    private func matchesStatus(_ task: AppHabitTask) -> Bool {
        switch selectedStatus {
        case "Unmet": return !task.isCompleted
        case "Met": return task.isCompleted
        default: return true // "All"
        }
    }
    
    private func matchesDetails(_ task: AppHabitTask) -> Bool {
        // 1. Task Days Filter
        let selectedDate = days.indices.contains(selectedDayIndex) ? days[selectedDayIndex].fullDate : Date()
        let isWeekend = Calendar.current.isDateInWeekend(selectedDate)
        
        if task.taskDays == "Weekdays" && isWeekend {
            return false
        }
        if task.taskDays == "Weekends" && !isWeekend {
            return false
        }
        
        // 2. Time Range Filter (UI filter: selectedTime)
        if selectedTime != "All" {
            let filterTime: String
            if selectedTime == "Now" {
                let hour = Calendar.current.component(.hour, from: Date())
                if hour >= 5 && hour < 12 { filterTime = "Morning" }
                else if hour >= 12 && hour < 17 { filterTime = "Afternoon" }
                else { filterTime = "Evening" }
            } else {
                filterTime = selectedTime
            }
            
            if filterTime != "Anytime" {
                if task.timeRange != "Anytime" && task.timeRange != filterTime {
                    return false
                }
            } else {
                // If the filter is exactly "Anytime", we only show explicitly "Anytime" tasks
                if task.timeRange != "Anytime" {
                    return false
                }
            }
        }
        
        return true
    }

    private func resetTask(_ id: UUID) {
        guard let i = taskIndex(id) else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            if tasks[i].isCompleted {
                tasks[i].streakDays = max(0, tasks[i].streakDays - 1)
            }
            tasks[i].current = 0
            tasks[i].isCompleted = false
            tasks[i].isSkipped = false
            swipedTaskID = nil
        }
        refreshDayProgress()
    }

    // MARK: - Day-change auto-reset
    /// Compares today's date with the stored `lastActiveDate`.
    /// If they differ, resets every task's progress for the new day while preserving streak counts.
    private func resetTasksIfDayChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())

        guard lastActiveDate != todayString else { return }

        let startOfToday = Calendar.current.startOfDay(for: Date())

        // Day has changed — reset all tasks
        for i in tasks.indices {
            tasks[i].current = 0
            tasks[i].isCompleted = false
            tasks[i].isSkipped = false
            tasks[i].memoText = ""
            tasks[i].mood = nil
            // streakDays is intentionally preserved
            
            if let endDate = tasks[i].endDate, Calendar.current.startOfDay(for: endDate) < startOfToday {
                tasks[i].isHidden = true
            }
        }

        // Regenerate the week strip so the date numbers stay current
        days = ContentView.generateWeekDays(homeWeekBar: homeWeekBar)

        lastActiveDate = todayString
        refreshDayProgress()
    }

    // MARK: - Task Details bridging
    private func detailTask(from task: AppHabitTask) -> DailyPlanner.HabitTask {
        let lowerTitle = task.title.lowercased()
        let lowerUnit = task.unit.lowercased().trimmingCharacters(in: .whitespaces)
        let type: TaskType
        
        let isTimeUnit = lowerUnit == "hr" || lowerUnit == "hour" || lowerUnit == "hours" ||
                         lowerUnit == "min" || lowerUnit == "minute" || lowerUnit == "minutes" ||
                         lowerUnit == "sec" || lowerUnit == "second" || lowerUnit == "seconds"
                         
        if lowerTitle.contains("sleep") {
            type = .ringStats
        } else if isTimeUnit {
            type = .timer
        } else if lowerTitle.contains("less") {
            type = .limit(unit: task.unit)
        } else if lowerTitle.contains("drink") {
            type = .counter(unit: task.unit)
        } else {
            type = .simpleGoal(unit: task.unit)
        }

        return DailyPlanner.HabitTask(
            id: task.id,
            emoji: task.emoji,
            name: task.title,
            isFavorite: true,
            accentColor: task.fillColor,
            backgroundGradient: [task.fillColor.opacity(0.18), task.fillColor.opacity(0.32)],
            type: type,
            current: task.current,
            goal: task.goal,
            goalUnitLabel: task.unit,
            memoText: task.memoText,
            streakDays: task.streakDays
        )
    }

    private func handleTaskDetailAction(_ action: TaskDetailAction, for id: UUID) {
        guard let i = taskIndex(id) else { return }
        switch action {
        case .progressChanged(let newCurrent):
            applyDetailCurrent(newCurrent, to: id)
        case .memoUpdated(let newMemo):
            tasks[i].memoText = newMemo
        case .reset:
            tasks[i].current = 0
            if tasks[i].isCompleted {
                tasks[i].isCompleted = false
                tasks[i].streakDays = max(0, tasks[i].streakDays - 1)
            }
        case .delete:
            tasks.remove(at: i)
            NotificationManager.shared.cancelNotification(for: id.uuidString)
            AnalyticsManager.shared.logHabitDeleted()
            selectedDetailTaskID = nil
        case .archive:
            tasks[i].isHidden = true
            selectedDetailTaskID = nil
        case .edit:
            taskToEdit = tasks[i]
        }
    }

    private func applyDetailCurrent(_ newValue: Double, to id: UUID) {
        guard let i = taskIndex(id) else { return }
        tasks[i].current = min(max(newValue, 0), tasks[i].goal)
        if tasks[i].current >= tasks[i].goal, !tasks[i].isCompleted {
            tasks[i].isCompleted = true
            tasks[i].streakDays += 1
            AnalyticsManager.shared.logHabitCompleted()
        } else if tasks[i].current < tasks[i].goal, tasks[i].isCompleted {
            tasks[i].isCompleted = false
            tasks[i].streakDays = max(0, tasks[i].streakDays - 1)
        }
        refreshDayProgress()
    }

    // MARK: - Filter popup
    private var filterPopup: some View {
        VStack(alignment: .leading, spacing: 15) {
            filterRow(title: "Status", options: statusOptions, selection: $selectedStatus)

            VStack(alignment: .leading, spacing: 10) {
                Text("Time")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(timeOptions.chunked(into: 4).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { option in
                                filterPill(option, isSelected: selectedTime == option) {
                                    selectedTime = option
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.cardSurface)
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
        )
    }

    private func filterRow(title: String, options: [String], selection: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
                .frame(width: 60, alignment: .leading)

            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    filterPill(option, isSelected: selection.wrappedValue == option) {
                        selection.wrappedValue = option
                    }
                }
            }
        }
    }

    private func filterPill(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : inkPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(pinkGradient) : AnyShapeStyle(Color.cardSurface))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
            )
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    action()
                }
            }
    }
}

// MARK: - Habit Row (swipeable task card)

private struct HabitRowView: View {
    @Binding var task: AppHabitTask
    let isSwiped: Bool
    let onSwipeOpen: () -> Void
    let onSwipeClose: () -> Void
    let onComplete: () -> Void
    let onAdd: () -> Void
    let onSetProgress: (Double) -> Void
    let onSkip: () -> Void
    let onHide: () -> Void
    let onReset: () -> Void
    let onOpenDetail: () -> Void

    let pinkGradient: LinearGradient
    let pinkRed: Color
    let inkPrimary: Color
    let inkSecondary: Color

    private let buttonWidth: CGFloat = 54
    private let buttonSpacing: CGFloat = 8
    private var actionsWidth: CGFloat { buttonWidth * 4 + buttonSpacing * 3 }

    @GestureState private var dragOffset: CGFloat = 0

    // Left-to-right "drag to fill" progress state
    @State private var cardWidth: CGFloat = 0
    @State private var progressDragBaseline: CGFloat? = nil
    @State private var isDraggingProgress: Bool = false
    
    @AppStorage("checkInMethod") private var checkInMethod: String = "Swipe right to check in"

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .trailing) {
                HStack(spacing: buttonSpacing) {
                    actionButton(title: "Add", systemImage: "plus", tint: pinkRed, bg: pinkRed.opacity(0.12), action: onAdd)
                    actionButton(title: task.isSkipped ? "Unskip" : "Skip", systemImage: "chevron.forward.2",
                                 tint: .orange, bg: Color.orange.opacity(0.12), action: onSkip)
                    actionButton(title: "Hide", systemImage: "eye.slash", tint: .blue, bg: Color.blue.opacity(0.10), action: onHide)
                    actionButton(title: "Reset", systemImage: "arrow.clockwise", tint: .green, bg: Color.green.opacity(0.12), action: onReset)
                }
                .frame(width: actionsWidth)

                cardBody
                    .padding(.trailing, isSwiped ? 8 : 0)
                    .offset(x: currentOffset)
                    .gesture(cardDragGesture)
                    .onTapGesture {
                        if isSwiped {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { onSwipeClose() }
                        } else {
                            onOpenDetail()
                        }
                    }
                    .onChange(of: isSwiped) { _ in
                        progressDragBaseline = nil
                        isDraggingProgress = false
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Streak badge, overlapping the card's top-right corner, sitting above the clip.
            if task.streakDays > 0 && !isSwiped {
                HStack(spacing: 3) {
                    Text("🔥").font(.system(size: 10))
                    Text("\(task.streakDays) Day\(task.streakDays == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(inkPrimary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cardSurface))
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                .offset(x: -10, y: -10)
            }
        }
    }

    // MARK: - Combined gesture: swipe-left reveals actions, drag-right fills progress

    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragOffset) { value, state, _ in
                // Only negative translation drives the swipe-to-reveal offset.
                state = min(0, value.translation.width)
            }
            .onChanged { value in
                // While the actions row is revealed, a left-to-right drag should
                // only be able to close it back up — never fill progress.
                guard !isSwiped,
                      value.translation.width > 0,
                      !task.isCompleted, !task.isSkipped,
                      cardWidth > 0,
                      checkInMethod == "Swipe right to check in" else { return }

                isDraggingProgress = true
                if progressDragBaseline == nil {
                    progressDragBaseline = task.fraction
                }
                let delta = value.translation.width / cardWidth
                let newFraction = min(max((progressDragBaseline ?? 0) + delta, 0), 1)
                onSetProgress(Double(newFraction) * task.goal)
            }
            .onEnded { value in
                if isSwiped {
                    // Any drag while swiped just decides whether to stay open or close;
                    // it never touches progress.
                    progressDragBaseline = nil
                    isDraggingProgress = false
                    let shouldStayOpen = value.translation.width < -actionsWidth / 2
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        shouldStayOpen ? onSwipeOpen() : onSwipeClose()
                    }
                } else if value.translation.width > 0 {
                    progressDragBaseline = nil
                    isDraggingProgress = false
                } else {
                    let shouldOpen = value.translation.width < -actionsWidth / 2
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        shouldOpen ? onSwipeOpen() : onSwipeClose()
                    }
                }
            }
    }

    // MARK: - Card with progress fill bar

    private var cardBody: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.cardSurface
                task.baseColor

                if task.fraction > 0 {
                    task.fillColor
                        .frame(width: geo.size.width * task.fraction)
                        .animation(isDraggingProgress ? nil : .easeOut(duration: 0.2), value: task.fraction)
                }

                HStack(spacing: 12) {
                    Text(task.emoji)
                        .font(.system(size: 20))

                    if checkInMethod == "Tap to check in" {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(task.isSkipped ? task.textColor.opacity(0.4) : task.textColor)
                                .strikethrough(task.isSkipped)
                            Text(task.progressText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(task.textColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(task.textColor.opacity(0.15)))
                        }
                    } else {
                        Text(task.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(task.isSkipped ? task.textColor.opacity(0.4) : task.textColor)
                            .strikethrough(task.isSkipped)
                    }

                    Spacer()

                    if checkInMethod == "Tap to check in" {
                        Button(action: {
                            if !task.isCompleted && !task.isSkipped {
                                onComplete()
                            }
                        }) {
                            Circle()
                                .fill(task.isCompleted ? Color.white : task.textColor.opacity(0.1))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: task.isCompleted ? "checkmark" : "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(task.isCompleted ? task.fillColor : task.textColor.opacity(0.3))
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(task.progressText)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(task.textColor)
                    }
                }
                .padding(.horizontal, 18)
            }
            .contentShape(Rectangle())
            .onAppear { cardWidth = geo.size.width }
            .onChange(of: geo.size.width) { newValue in
                cardWidth = newValue
            }
        }
        .frame(height: 70)
    }

    private var currentOffset: CGFloat {
        let base: CGFloat = isSwiped ? -actionsWidth : 0
        return base + dragOffset * (isSwiped ? 0.3 : 1.0)
    }

    private func actionButton(title: String, systemImage: String, tint: Color, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .foregroundColor(tint)
            .frame(width: buttonWidth)
            .frame(maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(bg))
        }
    }
}

#Preview {
    ContentView()
}
