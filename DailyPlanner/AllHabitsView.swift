//
//  AllHabitsView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 27/07/26.
//

import SwiftUI

// MARK: - All Habits (Habit Manager)

struct AllHabitsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager
    @EnvironmentObject private var storeManager: StoreManager

    @AppStorage("savedTasks") private var tasks: [AppHabitTask] = []

    private var activeTasks: [AppHabitTask] {
        tasks.filter { !$0.isHidden }
    }

    private var archivedTasks: [AppHabitTask] {
        tasks.filter { $0.isHidden }
    }

    @State private var isDeleteMode = false
    @State private var selectedIDs: Set<UUID> = []

    @State private var showSortSheet = false
    @State private var showNewHabit = false
    @State private var showPremiumPaywall = false
    
    @State private var habitToEdit: AppHabitTask? = nil
    @State private var taskToReset: AppHabitTask? = nil
    @State private var showResetConfirm = false
    
    private let habitColors = ["4CB86B", "8C99C7", "38ADDB", "6B52D9", "D98C3A", "6BA83A", "D9524A", "9B59B6", "3A8FD9", "E0B23A"]

    var body: some View {
        ScrollView(showsIndicators: false) {

            if activeTasks.isEmpty && archivedTasks.isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 120)
                    Image(systemName: "clipboard")
                        .font(.system(size: 54, weight: .light))
                        .foregroundColor(themeManager.primaryColor.opacity(0.6))
                    
                    Text("No Habits Found")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Tap the + button below to create your first habit and start tracking!")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 20) {

                    VStack(spacing: 12) {
                        ForEach(activeTasks) { task in
                            HabitRow(
                                habit: task,
                                isDeleteMode: isDeleteMode,
                                isSelected: selectedIDs.contains(task.id),
                                isArchived: false,
                                onToggleSelect: { toggleSelect(task) },
                                onArchive: { archive(task) },
                                onActivate: {},
                                onDelete: { delete(task) },
                                onEdit: { habitToEdit = task },
                                onReset: { resetData(task) }
                            )
                        }
                    }

                    if !archivedTasks.isEmpty {
                        Text("Archived")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.top, 4)

                        VStack(spacing: 12) {
                            ForEach(archivedTasks) { task in
                                HabitRow(
                                    habit: task,
                                    isDeleteMode: false,
                                    isSelected: false,
                                    isArchived: true,
                                    onToggleSelect: {},
                                    onArchive: {},
                                    onActivate: { activate(task) },
                                    onDelete: { delete(task) },
                                    onEdit: {},
                                    onReset: {}
                                )
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 90) // room for the floating button
            }
        }
        .background(Color.pageSurface)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .overlay(alignment: .bottom) { bottomButton }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interHabitManagerID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interHabitManager")
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSortSheet) {
            SortHabitsSheet(tasks: $tasks)
        }
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumUpgradeView()
        }
        .fullScreenCover(isPresented: $showNewHabit) {
            NewHabitView { emoji, name, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType in
                saveNewHabit(emoji: emoji, name: name, goal: goal, unit: unit, colorHex: colorHex, endDate: endDate, goalPeriod: goalPeriod, habitType: habitType, taskDays: taskDays, timeRange: timeRange, chartType: chartType)
            }
        }
        .fullScreenCover(item: $habitToEdit) { task in
            HabitDetailView(taskToEdit: task) { emoji, name, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType in
                updateHabit(id: task.id, emoji: emoji, name: name, goal: goal, unit: unit, colorHex: colorHex, endDate: endDate, goalPeriod: goalPeriod, habitType: habitType, taskDays: taskDays, timeRange: timeRange, chartType: chartType)
            }
        }
        .alert("Reset Habit Data", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                if let task = taskToReset {
                    performReset(task)
                }
            }
        } message: {
            Text("Are you sure you want to delete all history and stats for this habit? This cannot be undone.")
        }
    }

    // MARK: Actions

    private func saveNewHabit(emoji: String, name: String, goal: Double, unit: String, colorHex: String, endDate: Date?, goalPeriod: String, habitType: String, taskDays: String, timeRange: String, chartType: Int) {
        let newTask = AppHabitTask(
            emoji: emoji,
            title: name,
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
        withAnimation {
            tasks.append(newTask)
        }
    }

    private func toggleSelect(_ task: AppHabitTask) {
        if selectedIDs.contains(task.id) {
            selectedIDs.remove(task.id)
        } else {
            selectedIDs.insert(task.id)
        }
    }

    private func archive(_ task: AppHabitTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isHidden = true
        }
    }

    private func activate(_ task: AppHabitTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isHidden = false
        }
    }

    private func delete(_ task: AppHabitTask) {
        tasks.removeAll { $0.id == task.id }
        selectedIDs.remove(task.id)
        NotificationManager.shared.cancelNotification(for: task.id.uuidString)
        AnalyticsManager.shared.logHabitDeleted()
    }

    private func deleteSelected() {
        for id in selectedIDs {
            NotificationManager.shared.cancelNotification(for: id.uuidString)
            AnalyticsManager.shared.logHabitDeleted()
        }
        tasks.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        withAnimation { isDeleteMode = false }
    }

    private func updateHabit(id: UUID, emoji: String, name: String, goal: Double, unit: String, colorHex: String, endDate: Date?, goalPeriod: String, habitType: String, taskDays: String, timeRange: String, chartType: Int) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            withAnimation {
                tasks[idx].emoji = emoji
                tasks[idx].title = name
                tasks[idx].goal = goal
                tasks[idx].unit = unit
                tasks[idx].colorHex = colorHex
                tasks[idx].endDate = endDate
                tasks[idx].goalPeriod = goalPeriod
                tasks[idx].habitType = habitType
                tasks[idx].taskDays = taskDays
                tasks[idx].timeRange = timeRange
                tasks[idx].chartType = chartType
            }
        }
    }

    private func resetData(_ task: AppHabitTask) {
        taskToReset = task
        showResetConfirm = true
    }

    private func performReset(_ task: AppHabitTask) {
        HabitHistoryStore.deleteAll(for: task.title)
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation {
                tasks[idx].current = 0
                tasks[idx].streakDays = 0
                tasks[idx].isCompleted = false
                tasks[idx].isSkipped = false
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interHabitManagerFlag,
                    adKey: "interHabitManager",
                    adUnitID: RemoteConfigManager.shared.interHabitManagerID
                )
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("All Habits")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    showSortSheet = true
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(themeManager.primaryColor))
                }

                Button {
                    withAnimation {
                        isDeleteMode.toggle()
                        selectedIDs.removeAll()
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(themeManager.primaryColor))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.pageSurface)
    }

    // MARK: Floating bottom button

    private var bottomButton: some View {
        Button {
            if isDeleteMode {
                deleteSelected()
            } else {
                if !storeManager.isPremium && tasks.count >= StoreManager.freeHabitLimit {
                    showPremiumPaywall = true
                } else {
                    showNewHabit = true
                }
            }
        } label: {
            Image(systemName: isDeleteMode ? "trash.fill" : "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle().fill(themeManager.horizontalGradient)
                )
                .shadow(color: themeManager.primaryColor.opacity(0.4), radius: 10, y: 6)
        }
        .padding(.bottom, 24)
        .disabled(isDeleteMode && selectedIDs.isEmpty)
        .opacity(isDeleteMode && selectedIDs.isEmpty ? 0.5 : 1)
    }
}

// MARK: - Habit Row

private struct HabitRow: View {

    @EnvironmentObject private var themeManager: AppThemeManager

    let habit: AppHabitTask
    let isDeleteMode: Bool
    let isSelected: Bool
    let isArchived: Bool
    let onToggleSelect: () -> Void
    let onArchive: () -> Void
    let onActivate: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 14) {

            Text(habit.emoji)
                .font(.system(size: 30))

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text("Build")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.primaryColor)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.primaryColor)
                }
            }

            Spacer()

            if isDeleteMode {
                Button(action: onToggleSelect) {
                    Circle()
                        .strokeBorder(isSelected ? themeManager.primaryColor : Color.gray.opacity(0.4), lineWidth: 2)
                        .background(Circle().fill(isSelected ? themeManager.primaryColor : Color.clear))
                        .frame(width: 26, height: 26)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            } else if isArchived {
                Menu {
                    Button {
                        onActivate()
                    } label: {
                        Label("Activate", systemImage: "arrow.uturn.up")
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.gray.opacity(0.12)))
                }
            } else {
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        onArchive()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }

                    Button {
                        onReset()
                    } label: {
                        Label("Reset All Data", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.gray.opacity(0.12)))
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 74)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Sort / Reorder sheet

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
        .background(Color.pageSurface)
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
    NavigationStack {
        AllHabitsView()
            .environmentObject(AppThemeManager())
    }
}
