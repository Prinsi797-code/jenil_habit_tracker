//
//  TaskListViewModel.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published var tasks: [HabitTask] = HabitTask.all
    @Published var selectedIndex: Int = 0
 
    var selectedTask: HabitTask {
        tasks[selectedIndex]
    }
}
