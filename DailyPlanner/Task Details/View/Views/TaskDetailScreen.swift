//
//  TaskDetailScreen.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI

enum TaskDetailAction {
    case progressChanged(Double)
    case memoUpdated(String)
    case reset
    case delete
    case edit
    case archive
}

struct TaskDetailScreen: View {
    @StateObject var viewModel: TaskDetailViewModel
    var onAction: ((TaskDetailAction) -> Void)? = nil
    
    init(task: HabitTask, onAction: ((TaskDetailAction) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
        self.onAction = onAction
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: viewModel.backgroundGradient,
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TaskHeaderView(emoji: viewModel.emoji,
                               name: viewModel.name,
                               isFavorite: viewModel.isFavorite)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        bodyContent
                            .padding(.top, 24)
                        footerContent
                        
                        HabitChartView(habit: viewModel.task)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 8)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.actionHandler = onAction
            }
            .onChange(of: viewModel.current) { newValue in
                onAction?(.progressChanged(newValue))
            }
            .environmentObject(viewModel)
            .sheet(isPresented: $viewModel.showMemoSheet) {
                MemoSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showStatSheet) {
                StatSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showSleepLogSheet) {
                SleepLogSheet(viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    var bodyContent: some View {
        switch viewModel.type {
        case .counter(let unit):
            CounterBody(viewModel: viewModel, unit: unit)
        case .ringStats:
            RingStatsBody(viewModel: viewModel)
        case .timer:
            TimerBody(viewModel: viewModel)
        case .simpleGoal(_):
            SimpleGoalBody(viewModel: viewModel)
        case .limit(_):
            LimitBody(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    var footerContent: some View {
        switch viewModel.type {
        case .counter(_):
            CounterFooter(viewModel: viewModel, addAmount: viewModel.task.stepAmount)
        case .ringStats:
            MemoStatRow()
        case .timer:
            TimerFooter(viewModel: viewModel)
        case .simpleGoal(_):
            SimpleGoalFooter(viewModel: viewModel, addAmount: viewModel.task.stepAmount)
        case .limit(_):
            LimitFooter(viewModel: viewModel, addAmount: viewModel.task.stepAmount)
        }
    }
}

// MARK: - Sheets

struct MemoSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @State private var text: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TextEditor(text: $text)
                .padding()
                .navigationTitle("Memo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.saveMemo(text)
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    text = viewModel.task.memoText
                }
        }
    }
}

struct StatSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Progress")) {
                    HStack {
                        Text("Goal")
                        Spacer()
                        Text("\(viewModel.goal, specifier: "%.1f") \(viewModel.goalUnitLabel)")
                    }
                    HStack {
                        Text("Current")
                        Spacer()
                        Text("\(viewModel.current, specifier: "%.1f") \(viewModel.goalUnitLabel)")
                    }
                }
                Section(header: Text("Streaks")) {
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(viewModel.task.streakDays) Days")
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SleepLogSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hoursSlept: Double = 8.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Sleep")) {
                    Stepper(value: $hoursSlept, in: 0.0...24.0, step: 0.5) {
                        Text("\(hoursSlept, specifier: "%.1f") hours")
                    }
                }
            }
            .navigationTitle("Sleep Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.add(hoursSlept)
                        dismiss()
                    }
                }
            }
            .onAppear {
                hoursSlept = max(viewModel.goal - viewModel.current, 0)
            }
        }
    }
}
