//
//  TaskListContainerScreen.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
 
struct TaskListContainerScreen: View {
    @StateObject private var listViewModel = TaskListViewModel()
 
    var body: some View {
        NavigationView {
            TaskDetailScreen(task: listViewModel.selectedTask)
                .id(listViewModel.selectedIndex) // force fresh ViewModel per selection
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Picker("Task", selection: $listViewModel.selectedIndex) {
                            ForEach(listViewModel.tasks.indices, id: \.self) { i in
                                Text(listViewModel.tasks[i].name).tag(i)
                            }
                        }
                    }
                }
        }
    }
}
 
#Preview("Drink Water") { TaskDetailScreen(task: .drinkWater) }
#Preview("Sleep") { TaskDetailScreen(task: .sleep) }
#Preview("Meditation") { TaskDetailScreen(task: .meditation) }
#Preview("Cycling") { TaskDetailScreen(task: .cycling) }
#Preview("Stand") { TaskDetailScreen(task: .stand) }
#Preview("Walk") { TaskDetailScreen(task: .walk) }
#Preview("Run") { TaskDetailScreen(task: .run) }
#Preview("Workout") { TaskDetailScreen(task: .workout) }
#Preview("Exercise") { TaskDetailScreen(task: .exercise) }
#Preview("Active Calorie") { TaskDetailScreen(task: .activeCalorie) }
#Preview("Burn Calorie") { TaskDetailScreen(task: .burnCalorie) }
#Preview("Read a Book") { TaskDetailScreen(task: .readABook) }
#Preview("Drink Less Alcohol") { TaskDetailScreen(task: .drinkLessAlcohol) }
#Preview("Drink Less Caffeine") { TaskDetailScreen(task: .drinkLessCaffeine) }
#Preview("Switcher") { TaskListContainerScreen() }
