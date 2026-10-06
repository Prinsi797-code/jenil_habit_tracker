//
//  HabitDetailView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//

import SwiftUI

struct HabitDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let habitEmoji: String
    let isCustom: Bool
    let isEditing: Bool

    @State private var name: String
    @State private var description: String = ""

    @State private var habitType: String = "Build"
    @State private var appleHealthSync: Bool = false

    @State private var goalPeriod: String = "Day-Long"
    @State private var goalAmount: String
    @State private var goalUnit: String
    @State private var taskDays: String = "Every Day"
    
    @State private var showGoalValueSheet = false
    @State private var showColorPicker = false
    @State private var selectedColorHex = "#74B9FF"

    @State private var selectedTimeRange: String = "Anytime"
    private let timeRanges = ["Anytime", "Morning", "Afternoon", "Evening"]

    @State private var remindersOn: Bool = false
    @State private var superAlertOn: Bool = false
    @State private var reminderTimes: [String] = ["19:30"]
    @State private var ringtone: String = "Default"
    @State private var reminderMessage: String = ""

    @State private var showMemoAfterCompletion: Bool = true
    @State private var habitBarGesture: String = "Mark as done"
    @State private var chartType: Int = 0

    @State private var startDateValue: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDateValue: Date = Date().addingTimeInterval(86400)

    var onSave: ((String, String, Double, String, String, Date?, String, String, String, String, Int) -> Void)?

    init(emoji: String = "⭐", name: String = "", isCustom: Bool = false, taskToEdit: AppHabitTask? = nil, onSave: ((String, String, Double, String, String, Date?, String, String, String, String, Int) -> Void)? = nil) {
        self.habitEmoji = emoji
        self.isCustom = isCustom
        self.isEditing = (taskToEdit != nil)
        self.onSave = onSave
        
        if let task = taskToEdit {
            _name = State(initialValue: task.title)
            _goalAmount = State(initialValue: String(format: "%.0f", task.goal))
            _goalUnit = State(initialValue: task.unit)
            _selectedColorHex = State(initialValue: task.fillColor.toHex())
            _goalPeriod = State(initialValue: task.goalPeriod)
            _habitType = State(initialValue: task.habitType)
            _taskDays = State(initialValue: task.taskDays)
            _selectedTimeRange = State(initialValue: task.timeRange)
            _chartType = State(initialValue: task.chartType)
            if let endDate = task.endDate {
                _hasEndDate = State(initialValue: true)
                _endDateValue = State(initialValue: endDate)
            }
        } else {
            _name = State(initialValue: name)
            if isCustom {
                _goalAmount = State(initialValue: "1")
                _goalUnit = State(initialValue: "count")
            } else {
                let defaults = HabitDetailView.defaultGoal(for: name)
                _goalAmount = State(initialValue: defaults.0)
                _goalUnit = State(initialValue: defaults.1)
            }
        }
    }
    
    private static func defaultGoal(for name: String) -> (String, String) {
        let n = name.lowercased()
        if n.contains("water") || n.contains("drink") { return ("2000", "ml") }
        if n.contains("sleep") { return ("8", "hr") }
        if n.contains("read") || n.contains("book") { return ("15", "pages") }
        if n.contains("run") || n.contains("cycl") || n.contains("walk") { return ("5", "km") }
        if n.contains("meditat") || n.contains("workout") || n.contains("exercise") { return ("30", "min") }
        if n.contains("calorie") || n.contains("energy") { return ("500", "kcal") }
        if n.contains("step") { return ("5000", "steps") }
        return ("1", "count")
    }

    // MARK: - Palette

    private var baseColor: Color {
        Color(hex: selectedColorHex) ?? Color(red: 0.40, green: 0.49, blue: 0.80)
    }

    private var cardBlue: Color { baseColor }
    private var cardBlueDeep: Color { baseColor.opacity(0.85) }
    private var pageBackground: Color { baseColor.opacity(0.15) }
    private var cardBackground: Color {
        colorScheme == .dark ? (Color(hex: "#1A1919") ?? Color.black) : Color(.systemBackground)
    }

    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    private let orangeNote = Color(red: 0.93, green: 0.53, blue: 0.28)
    private let pillTrack = Color(.tertiarySystemFill)

    private var headerTitle: String {
        if isCustom { return "Custom Habit" }
        return name.isEmpty ? "Habit" : name
    }

    private var goalAmountDescription: String {
        "\(goalAmount) \(goalUnit)"
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    identityCard
                    habitTypeCard
                    appleHealthSyncCard
                    goalCard
                    timeRangeCard
                    reminderCard
                    habitTermCard
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interHabitDetailID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interHabitDetail")
        }
        .sheet(isPresented: $showGoalValueSheet) {
            GoalValueView(goalAmount: $goalAmount, goalUnit: $goalUnit)
        }
        .sheet(isPresented: $showColorPicker) {
            HabitColorPickerView(selectedColorHex: $selectedColorHex)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interHabitDetailFlag,
                    adKey: "interHabitDetail",
                    adUnitID: RemoteConfigManager.shared.interHabitDetailID
                )
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(inkPrimary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }

            Spacer()

            HStack(spacing: 8) {
                Text(habitEmoji)
                    .font(.system(size: 20))
                Text(headerTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
            }

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Cards

    private var identityCard: some View {
        card {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(cardBlue.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(width: 64, height: 64)
                        .overlay(Text(habitEmoji).font(.system(size: 30)))

                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Habit name", text: $name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(inkPrimary)

                        Divider()

                        TextField("Description (Optional)", text: $description)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(inkSecondary)
                    }
                }

                Divider()

                Button(action: { showColorPicker = true }) {
                    disclosureRow(title: "Color") {
                        Capsule()
                            .fill(Color(hex: selectedColorHex) ?? cardBlue)
                            .frame(width: 40, height: 30)
                    }
                }
                .buttonStyle(.plain)

            }
        }
    }

    private var habitTypeCard: some View {
        card {
            disclosureRow(title: "Habit Type", helpIcon: true) {
                Menu {
                    Button("Build", action: { habitType = "Build" })
                    Button("Quit", action: { habitType = "Quit" })
                } label: {
                    Text(habitType)
                        .font(.system(size: 17, design: .rounded))
                        .foregroundColor(inkPrimary)
                }
            }
        }
    }

    private var appleHealthSyncCard: some View {
        card {
            HStack {
                titleWithHelp("Apple Health Sync", helpIcon: true)
                Spacer()
                Toggle("", isOn: $appleHealthSync)
                    .labelsHidden()
                    .tint(cardBlue)
            }
        }
    }

    private var goalCard: some View {
        card {
            VStack(spacing: 0) {
                disclosureRow(title: "Goal Period", helpIcon: true) {
                    Menu {
                        Button("Day-Long", action: { goalPeriod = "Day-Long" })
                        Button("Morning", action: { goalPeriod = "Morning" })
                        Button("Afternoon", action: { goalPeriod = "Afternoon" })
                        Button("Evening", action: { goalPeriod = "Evening" })
                    } label: {
                        Text(goalPeriod).font(.system(size: 17, design: .rounded)).foregroundColor(inkPrimary)
                    }
                }
                Divider().padding(.vertical, 14)

                Button(action: { showGoalValueSheet = true }) {
                    disclosureRow(title: "Goal Value") {
                        Text("\(goalAmount) \(goalUnit)")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundColor(inkPrimary)
                    }
                }
                Divider().padding(.vertical, 14)

                disclosureRow(title: "Task Days") {
                    Menu {
                        Button("Every Day", action: { taskDays = "Every Day" })
                        Button("Weekdays", action: { taskDays = "Weekdays" })
                        Button("Weekends", action: { taskDays = "Weekends" })
                    } label: {
                        Text(taskDays).font(.system(size: 17, design: .rounded)).foregroundColor(inkPrimary)
                    }
                }

                HStack {
                    Text("*Complete \(goalAmountDescription) each day")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(orangeNote)
                    Spacer()
                }
                .padding(.top, 12)
            }
        }
    }

    private var timeRangeCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Time Range")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(timeRanges, id: \.self) { range in
                            timeRangePill(range)
                        }
                    }
                }
            }
        }
    }

    private var reminderCard: some View {
        card {
            VStack(spacing: 0) {
                HStack {
                    titleWithHelp("Reminders")
                    Spacer()
                    Toggle("", isOn: $remindersOn).labelsHidden().tint(cardBlue)
                }

                if remindersOn {
                    Divider().padding(.vertical, 14)

                    HStack {
                        titleWithHelp("Super Alert", helpIcon: true)
                        Spacer()
                        Toggle("", isOn: $superAlertOn).labelsHidden().tint(cardBlue)
                    }

                    Divider().padding(.vertical, 14)

                    HStack {
                        Text("Time").font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(inkPrimary)
                        Spacer()
                        Button(action: { reminderTimes.append("08:00") }) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 30)
                                .background(Capsule().fill(cardBlue))
                        }
                    }

                    if !reminderTimes.isEmpty {
                        HStack {
                            ForEach(reminderTimes, id: \.self) { time in
                                Text(time)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(cardBlue))
                            }
                            Spacer()
                        }
                        .padding(.top, 12)
                    }

                    Divider().padding(.vertical, 14)

                    disclosureRow(title: "Ringtone") {
                        Text(ringtone).font(.system(size: 17, design: .rounded)).foregroundColor(inkPrimary)
                    }

                    Divider().padding(.vertical, 14)

                    TextField("Reminder message", text: $reminderMessage)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(inkSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(pillTrack))
                }

                Divider().padding(.vertical, 14)

                HStack {
                    Text("Show memo after completion")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(inkPrimary)
                    Spacer()
                    Toggle("", isOn: $showMemoAfterCompletion).labelsHidden().tint(cardBlue)
                }
            }
        }
    }

    private var habitTermCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Habit Term")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date").font(.system(size: 14, design: .rounded)).foregroundColor(inkMuted)
                        DatePicker("", selection: $startDateValue, displayedComponents: .date)
                            .labelsHidden()
                            .tint(cardBlue)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("End Date").font(.system(size: 14, design: .rounded)).foregroundColor(inkMuted)
                            Toggle("", isOn: $hasEndDate).labelsHidden().tint(cardBlue)
                        }
                        if hasEndDate {
                            DatePicker("", selection: $endDateValue, displayedComponents: .date)
                                .labelsHidden()
                                .tint(cardBlue)
                        } else {
                            Text("No End")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(inkSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(pillTrack))
                        }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: {
            let goalDouble = Double(goalAmount) ?? 1.0
            
            if isEditing {
                AnalyticsManager.shared.logHabitEdited()
            } else {
                AnalyticsManager.shared.logHabitCreated(habitType: habitType, hasReminder: remindersOn, hasEndDate: hasEndDate)
            }
            
            onSave?(habitEmoji, name.isEmpty ? "New Habit" : name, goalDouble, goalUnit, selectedColorHex, hasEndDate ? endDateValue : nil, goalPeriod, habitType, taskDays, selectedTimeRange, chartType)
            dismiss()
        }) {
            Text("Save")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(LinearGradient(colors: [cardBlue, cardBlueDeep], startPoint: .leading, endPoint: .trailing)))
                .shadow(color: cardBlue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.top, 6)
    }

    // MARK: - Helpers

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(cardBackground))
    }

    private func titleWithHelp(_ title: String, helpIcon: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
        }
    }

    private func disclosureRow<Value: View>(title: String, helpIcon: Bool = false, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            titleWithHelp(title, helpIcon: helpIcon)
            Spacer()
            value()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(inkMuted)
        }
    }

    private func timeRangePill(_ range: String) -> some View {
        let isSelected = range == selectedTimeRange

        return Text(range)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(isSelected ? .white : inkSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(LinearGradient(colors: [cardBlue, cardBlueDeep], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(pillTrack))
            )
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedTimeRange = range
                }
            }
    }

    private func chartTypeButton(icon: String, index: Int) -> some View {
        let isSelected = chartType == index

        return Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isSelected ? .white : inkSecondary)
            .frame(width: 52, height: 34)
            .background(Capsule().fill(isSelected ? AnyShapeStyle(cardBlue) : AnyShapeStyle(pillTrack)))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    chartType = index
                }
            }
    }
}

#Preview("Preset habit") {
    HabitDetailView(emoji: "🚶‍♀️", name: "Walk")
}

#Preview("Custom habit") {
    HabitDetailView(emoji: "⭐", name: "", isCustom: true)
}
