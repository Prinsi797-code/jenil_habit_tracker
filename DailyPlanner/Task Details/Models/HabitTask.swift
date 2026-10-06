//
//  HabitTask.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
 
enum TaskType {
    case counter(unit: String)       // Drink Water
    case ringStats                   // Sleep
    case timer                       // Meditation, Workout
    case simpleGoal(unit: String)    // Stand, Walk, Run, Cycling, Exercise, Read a Book
    case limit(unit: String)         // Drink Less Alcohol/Caffeine
}
 
struct HabitTask: Identifiable {
    var id: UUID = UUID()
    let emoji: String
    let name: String
    let isFavorite: Bool
    let accentColor: Color
    let backgroundGradient: [Color]
    let type: TaskType
    var current: Double = 0
    var goal: Double = 0
    var goalUnitLabel: String = ""
    var memoText: String = ""
    var streakDays: Int = 0
    var stepAmount: Double = 1.0
}
 
// MARK: - Presets matching your app's habit list
 
extension HabitTask {
    static let drinkWater = HabitTask(
        emoji: "💧", name: "Drink water", isFavorite: true,
        accentColor: .cyan,
        backgroundGradient: [Color(red: 0.85, green: 0.97, blue: 1.0), Color(red: 0.78, green: 0.94, blue: 1.0)],
        type: .counter(unit: "ml"),
        current: 500, goal: 3000, goalUnitLabel: "ml", stepAmount: 250
    )
 
    static let sleep = HabitTask(
        emoji: "🛌", name: "Sleep", isFavorite: true,
        accentColor: Color(red: 0.51, green: 0.44, blue: 0.93),
        backgroundGradient: [Color(red: 0.90, green: 0.87, blue: 0.98), Color(red: 0.93, green: 0.90, blue: 0.99)],
        type: .ringStats,
        current: 0, goal: 7, goalUnitLabel: "hr"
    )
 
    static let meditation = HabitTask(
        emoji: "🧘", name: "Meditation", isFavorite: true,
        accentColor: Color(red: 0.55, green: 0.70, blue: 0.80),
        backgroundGradient: [Color(red: 0.90, green: 0.96, blue: 0.99), Color(red: 0.93, green: 0.97, blue: 0.99)],
        type: .timer,
        current: 1, goal: 30, goalUnitLabel: "min"
    )
 
    static let cycling = HabitTask(
        emoji: "🚴", name: "Cycling", isFavorite: true,
        accentColor: .blue,
        backgroundGradient: [Color(red: 0.80, green: 0.92, blue: 1.0), Color(red: 0.85, green: 0.95, blue: 1.0)],
        type: .simpleGoal(unit: "m"),
        current: 0, goal: 3000, goalUnitLabel: "m", stepAmount: 100
    )
 
    static let stand = HabitTask(
        emoji: "🧍‍♀️", name: "Stand", isFavorite: true,
        accentColor: .orange,
        backgroundGradient: [Color(red: 1.0, green: 0.93, blue: 0.85), Color(red: 1.0, green: 0.95, blue: 0.90)],
        type: .simpleGoal(unit: "hr"),
        current: 0, goal: 8, goalUnitLabel: "hr"
    )
 
    static let walk = HabitTask(
        emoji: "🚶", name: "Walk", isFavorite: true,
        accentColor: .green,
        backgroundGradient: [Color(red: 0.87, green: 0.97, blue: 0.88), Color(red: 0.92, green: 0.98, blue: 0.92)],
        type: .simpleGoal(unit: "steps"),
        current: 0, goal: 10000, goalUnitLabel: "steps", stepAmount: 500
    )
 
    static let run = HabitTask(
        emoji: "🏃", name: "Run", isFavorite: true,
        accentColor: .indigo,
        backgroundGradient: [Color(red: 0.88, green: 0.90, blue: 1.0), Color(red: 0.93, green: 0.94, blue: 1.0)],
        type: .simpleGoal(unit: "m"),
        current: 0, goal: 5000, goalUnitLabel: "m", stepAmount: 100
    )
 
    static let workout = HabitTask(
        emoji: "💪", name: "Workout", isFavorite: true,
        accentColor: .red,
        backgroundGradient: [Color(red: 1.0, green: 0.90, blue: 0.90), Color(red: 1.0, green: 0.94, blue: 0.94)],
        type: .timer,
        current: 1, goal: 45, goalUnitLabel: "min"
    )
 
    static let exercise = HabitTask(
        emoji: "🏃‍♂️", name: "Exercise", isFavorite: true,
        accentColor: Color.defaultPrimary,
        backgroundGradient: [Color(red: 1.0, green: 0.90, blue: 0.95), Color(red: 1.0, green: 0.94, blue: 0.97)],
        type: .simpleGoal(unit: "min"),
        current: 0, goal: 30, goalUnitLabel: "min"
    )
 
    static let activeCalorie = HabitTask(
        emoji: "🔥", name: "Active Calorie", isFavorite: true,
        accentColor: .orange,
        backgroundGradient: [Color(red: 1.0, green: 0.92, blue: 0.85), Color(red: 1.0, green: 0.95, blue: 0.90)],
        type: .simpleGoal(unit: "kcal"),
        current: 0, goal: 500, goalUnitLabel: "kcal"
    )
 
    static let burnCalorie = HabitTask(
        emoji: "🔥", name: "Burn Calorie", isFavorite: true,
        accentColor: .red,
        backgroundGradient: [Color(red: 1.0, green: 0.88, blue: 0.85), Color(red: 1.0, green: 0.92, blue: 0.90)],
        type: .simpleGoal(unit: "kcal"),
        current: 0, goal: 800, goalUnitLabel: "kcal"
    )
 
    static let readABook = HabitTask(
        emoji: "📚", name: "Read a book", isFavorite: false,
        accentColor: .brown,
        backgroundGradient: [Color(red: 0.96, green: 0.93, blue: 0.87), Color(red: 0.98, green: 0.96, blue: 0.92)],
        type: .simpleGoal(unit: "min"),
        current: 0, goal: 20, goalUnitLabel: "min"
    )
 
    static let drinkLessAlcohol = HabitTask(
        emoji: "🍺", name: "Drink Less Alcohol", isFavorite: true,
        accentColor: .yellow,
        backgroundGradient: [Color(red: 1.0, green: 0.97, blue: 0.85), Color(red: 1.0, green: 0.98, blue: 0.90)],
        type: .limit(unit: "drinks"),
        current: 0, goal: 2, goalUnitLabel: "drinks"
    )
 
    static let drinkLessCaffeine = HabitTask(
        emoji: "☕", name: "Drink Less Caffeine", isFavorite: true,
        accentColor: .brown,
        backgroundGradient: [Color(red: 0.94, green: 0.88, blue: 0.80), Color(red: 0.97, green: 0.93, blue: 0.88)],
        type: .limit(unit: "cups"),
        current: 0, goal: 2, goalUnitLabel: "cups"
    )
 
    static let all: [HabitTask] = [
        .drinkWater, .sleep, .meditation, .cycling, .stand,
        .walk, .run, .workout, .exercise,
        .activeCalorie, .burnCalorie, .readABook,
        .drinkLessAlcohol, .drinkLessCaffeine
    ]
}
