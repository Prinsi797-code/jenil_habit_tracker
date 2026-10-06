//
//  HabitCategories.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 31/07/26.
//

import Foundation

// MARK: - Habit Category Model

struct HabitItem: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let hasFavorite: Bool
}

struct HabitCategory {
    let name: String
    let icon: String
    let items: [HabitItem]
}

// MARK: - Categorized Habit Data

let habitCategories: [HabitCategory] = [
    HabitCategory(
        name: "Popular",
        icon: "flame.fill",
        items: [
            HabitItem(emoji: "🚶‍♀️", name: "Walk", hasFavorite: true),
            HabitItem(emoji: "🛏️", name: "Sleep", hasFavorite: true),
            HabitItem(emoji: "💧", name: "Drink water", hasFavorite: true),
            HabitItem(emoji: "🧘", name: "Meditation", hasFavorite: true),
            HabitItem(emoji: "🏃", name: "Run", hasFavorite: true),
            HabitItem(emoji: "🏃‍♂️", name: "Exercise", hasFavorite: true),
            HabitItem(emoji: "🚴", name: "Cycling", hasFavorite: true),
            HabitItem(emoji: "💪", name: "Workout", hasFavorite: true),
            HabitItem(emoji: "🧍", name: "Stand", hasFavorite: true),
            HabitItem(emoji: "🔥", name: "Active Calorie", hasFavorite: true),
            HabitItem(emoji: "🔥", name: "Burn Calorie", hasFavorite: true),
            HabitItem(emoji: "📚", name: "Read a book", hasFavorite: false),
            HabitItem(emoji: "🍺", name: "Drink Less Alcohol", hasFavorite: true),
            HabitItem(emoji: "☕️", name: "Drink Less Caffeine", hasFavorite: true)
        ]
    ),
    HabitCategory(
        name: "Health",
        icon: "heart.fill",
        items: [
            HabitItem(emoji: "🚶‍♀️", name: "Walk", hasFavorite: true),
            HabitItem(emoji: "🧍", name: "Stand", hasFavorite: true),
            HabitItem(emoji: "🛏️", name: "Sleep", hasFavorite: true),
            HabitItem(emoji: "🚴", name: "Cycling", hasFavorite: true),
            HabitItem(emoji: "🏃‍♂️", name: "Exercise", hasFavorite: true),
            HabitItem(emoji: "🔥", name: "Burn Calorie", hasFavorite: true),
            HabitItem(emoji: "💧", name: "Drink water", hasFavorite: true),
            HabitItem(emoji: "🧘", name: "Meditation", hasFavorite: true),
            HabitItem(emoji: "💪", name: "Workout", hasFavorite: true),
            HabitItem(emoji: "☕️", name: "Drink Less Caffeine", hasFavorite: true),
            HabitItem(emoji: "🍞", name: "Less Carbohydrate", hasFavorite: true)
        ]
    ),
    HabitCategory(
        name: "Sports",
        icon: "figure.run",
        items: [
            HabitItem(emoji: "🚶‍♀️", name: "Walk", hasFavorite: true),
            HabitItem(emoji: "🏃", name: "Run", hasFavorite: true),
            HabitItem(emoji: "🙆🏼‍♀️", name: "Stretch", hasFavorite: true),
            HabitItem(emoji: "🏃‍♂️", name: "Exercise", hasFavorite: true),
            HabitItem(emoji: "🚴", name: "Cycling", hasFavorite: true),
            HabitItem(emoji: "💪", name: "Workout", hasFavorite: true),
            HabitItem(emoji: "🧍", name: "Stand", hasFavorite: true),
            HabitItem(emoji: "🤸‍♂️", name: "Yoga", hasFavorite: true),
            HabitItem(emoji: "🏋️‍♀️", name: "Anaerobic", hasFavorite: false),
            HabitItem(emoji: "🏊‍♂️", name: "Swim", hasFavorite: true),
            HabitItem(emoji: "🔥", name: "Burn Calorie", hasFavorite: true)
        ]
    ),
    HabitCategory(
        name: "Lifestyle",
        icon: "house.fill",
        items: [
            HabitItem(emoji: "📔", name: "Track expenses", hasFavorite: false),
            HabitItem(emoji: "💰", name: "Save money", hasFavorite: false),
            HabitItem(emoji: "🍬", name: "Eat Less Sugar", hasFavorite: true),
            HabitItem(emoji: "😮‍💨", name: "Breathe", hasFavorite: false),
            HabitItem(emoji: "🧘", name: "Meditation", hasFavorite: true),
            HabitItem(emoji: "📚", name: "Read a book", hasFavorite: false),
            HabitItem(emoji: "🎓", name: "Learning", hasFavorite: false),
            HabitItem(emoji: "📼", name: "Review Today", hasFavorite: false),
            HabitItem(emoji: "💡", name: "Mind Clearing", hasFavorite: false),
            HabitItem(emoji: "💧", name: "Drink water", hasFavorite: true),
            HabitItem(emoji: "🍓", name: "Eat Fruits", hasFavorite: false),
            HabitItem(emoji: "🥬", name: "Eat Vege", hasFavorite: false),
            HabitItem(emoji: "🍬", name: "No Sugar", hasFavorite: false),
            HabitItem(emoji: "😴", name: "Sleep early", hasFavorite: false),
            HabitItem(emoji: "😆", name: "Laugh out loud", hasFavorite: false),
            HabitItem(emoji: "🥗", name: "Eat Low-Fat", hasFavorite: false),
            HabitItem(emoji: "🍎", name: "Eat an Apple", hasFavorite: false),
            HabitItem(emoji: "🥪", name: "Eat Breakfast", hasFavorite: false)
        ]
    ),
    HabitCategory(
        name: "Time",
        icon: "clock.fill",
        items: [
            HabitItem(emoji: "🙆🏼‍♀️", name: "Stretch", hasFavorite: true),
            HabitItem(emoji: "🤸‍♂️", name: "Yoga", hasFavorite: true),
            HabitItem(emoji: "🏊‍♂️", name: "Swim", hasFavorite: true),
            HabitItem(emoji: "🏃‍♂️", name: "Exercise", hasFavorite: true),
            HabitItem(emoji: "🏋️‍♀️", name: "Anaerobic", hasFavorite: false),
            HabitItem(emoji: "🧘", name: "Meditation", hasFavorite: true),
            HabitItem(emoji: "😮‍💨", name: "Breathe", hasFavorite: true),
            HabitItem(emoji: "📚", name: "Read a book", hasFavorite: false),
            HabitItem(emoji: "🎓", name: "Learning", hasFavorite: true),
            HabitItem(emoji: "📺", name: "Review Today", hasFavorite: true),
            HabitItem(emoji: "💡", name: "Mind Clearing", hasFavorite: true)
        ]
    ),
    HabitCategory(
        name: "Quit",
        icon: "nosign",
        items: [
            HabitItem(emoji: "🍞", name: "Less Carbohydrate", hasFavorite: true),
            HabitItem(emoji: "🍬", name: "Eat Less Sugar", hasFavorite: true),
            HabitItem(emoji: "☕️", name: "Drink Less Caffeine", hasFavorite: true),
            HabitItem(emoji: "🥤", name: "Drink Less Beverage", hasFavorite: false),
            HabitItem(emoji: "🍺", name: "Drink Less Alcohol", hasFavorite: true),
            HabitItem(emoji: "🚭", name: "Smoke Less", hasFavorite: false),
            HabitItem(emoji: "🎮", name: "Play Less Game", hasFavorite: false),
            HabitItem(emoji: "😤", name: "Complain Less", hasFavorite: false),
            HabitItem(emoji: "💺", name: "Sit Less", hasFavorite: false),
            HabitItem(emoji: "📺", name: "Watch Less TV", hasFavorite: false),
            HabitItem(emoji: "📱", name: "Less Social App", hasFavorite: false),
            HabitItem(emoji: "💰", name: "Spend Less", hasFavorite: false)
        ]
    )
]
