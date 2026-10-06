//
//  TaskDetailViewModel.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
 
@MainActor
final class TaskDetailViewModel: ObservableObject {
 
    @Published private(set) var task: HabitTask
    @Published var isTimerRunning: Bool = false
    
    // UI State for sheets
    @Published var showMemoSheet: Bool = false
    @Published var showStatSheet: Bool = false
    @Published var showSleepLogSheet: Bool = false
    
    // Callback to TaskDetailScreen for actions that modify the task in the root array
    var actionHandler: ((TaskDetailAction) -> Void)?

 
    private var timerCancellable: AnyCancellable?
 
    init(task: HabitTask) {
        self.task = task
    }
 
    // MARK: - Read-only display values (derived from the model)
 
    var emoji: String { task.emoji }
    var name: String { task.name }
    var isFavorite: Bool { task.isFavorite }
    var accentColor: Color { task.accentColor }
    var backgroundGradient: [Color] { task.backgroundGradient }
    var type: TaskType { task.type }
    var current: Double { task.current }
    var goal: Double { task.goal }
    var goalUnitLabel: String { task.goalUnitLabel }
 
    var progress: Double {
        guard task.goal > 0 else { return 0 }
        return min(max(task.current / task.goal, 0), 1)
    }
 
    var isOverLimit: Bool {
        task.current > task.goal
    }
 
    var countdownText: String {
        let remainingValue = max(task.goal - task.current, 0)
        
        let remainingSeconds: Int
        let lowerUnit = task.goalUnitLabel.lowercased().trimmingCharacters(in: .whitespaces)
        
        if lowerUnit == "hr" || lowerUnit == "hour" || lowerUnit == "hours" {
            remainingSeconds = Int(remainingValue * 3600)
        } else if lowerUnit == "sec" || lowerUnit == "second" || lowerUnit == "seconds" {
            remainingSeconds = Int(remainingValue)
        } else {
            // Default to minutes
            remainingSeconds = Int(remainingValue * 60)
        }
        
        let hrs = remainingSeconds / 3600
        let mins = (remainingSeconds % 3600) / 60
        let secs = remainingSeconds % 60
        
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
 
    // MARK: - Intents (the only way a View may change state)
 
    /// Generic "add" used by counter / simpleGoal / limit tasks.
    func add(_ amount: Double) {
        let actualAmount = min(amount, task.goal - task.current)
        task.current = min(task.current + amount, task.goal)
        
        // Save incremental progress to Apple Health
        if actualAmount > 0 {
            HealthKitManager.saveData(
                value: actualAmount,
                unit: task.goalUnitLabel,
                title: task.name
            )
        }
    }
 
    func reset() {
        task.current = 0
    }
 
    func toggleTimer() {
        isTimerRunning.toggle()
        
        if isTimerRunning {
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tick()
                }
        } else {
            timerCancellable?.cancel()
            timerCancellable = nil
            // Save accrued time when paused
            HealthKitManager.saveData(value: task.current, unit: task.goalUnitLabel, title: task.name)
        }
    }
    
    private func tick() {
        guard isTimerRunning else { return }
        
        let lowerUnit = task.goalUnitLabel.lowercased().trimmingCharacters(in: .whitespaces)
        let increment: Double
        if lowerUnit == "hr" || lowerUnit == "hour" || lowerUnit == "hours" {
            increment = 1.0 / 3600.0
        } else if lowerUnit == "sec" || lowerUnit == "second" || lowerUnit == "seconds" {
            increment = 1.0
        } else {
            increment = 1.0 / 60.0
        }
        
        task.current += increment
        
        if task.current >= task.goal {
            task.current = task.goal
            isTimerRunning = false
            timerCancellable?.cancel()
            timerCancellable = nil
            
            HealthKitManager.saveData(value: task.goal, unit: task.goalUnitLabel, title: task.name)
        }
    }
 
    func logSleep() {
        showSleepLogSheet = true
    }
 
    func markComplete() {
        task.current = task.goal
    }
    
    // MARK: - Navigation Actions
    
    func saveMemo(_ text: String) {
        task.memoText = text
        actionHandler?(.memoUpdated(text))
    }
    
    func resetProgress() {
        actionHandler?(.reset)
    }
    
    func deleteHabit() {
        actionHandler?(.delete)
    }
}
