//
//  HabitModels.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 25/07/26.
//

import SwiftUI
import Combine

// MARK: - Habit

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var emoji: String
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), emoji: String, name: String, colorHex: String) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.colorHex = colorHex
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

//extension Color {
//    /// Builds a Color from a "RRGGBB" hex string.
//    init(hex: String) {
//        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
//        var rgb: UInt64 = 0
//        Scanner(string: sanitized).scanHexInt64(&rgb)
//        let r = Double((rgb & 0xFF0000) >> 16) / 255
//        let g = Double((rgb & 0x00FF00) >> 8) / 255
//        let b = Double(rgb & 0x0000FF) / 255
//        self.init(red: r, green: g, blue: b)
//    }
//}

// MARK: - HabitStore

final class HabitStore: ObservableObject {

    @Published var habits: [Habit] = []
    /// "yyyy-MM-dd" -> set of habit ids completed that day.
    @Published private(set) var completions: [String: Set<UUID>] = [:]

    private let habitsKey = "habitTracker.habits.v1"
    private let completionsKey = "habitTracker.completions.v1"

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        return f
    }()

    static let defaultHabits: [Habit] = [
        Habit(emoji: "🚶", name: "Walk", colorHex: "5FCB9E"),
        Habit(emoji: "🧘", name: "Yoga", colorHex: "E8A0A0"),
        Habit(emoji: "🏊", name: "Swim", colorHex: "9BC3DA"),
        Habit(emoji: "🤸", name: "Stretch", colorHex: "C264AD"),
        Habit(emoji: "💧", name: "Drink Water", colorHex: "3FA1DB"),
        Habit(emoji: "🧍", name: "Stand", colorHex: "E0A458"),
        Habit(emoji: "🔥", name: "Burn Calorie", colorHex: "43D2C3"),
        Habit(emoji: "🍞", name: "Eat Breakfast", colorHex: "EFC373")
    ]

    init() {
        load()
        if habits.isEmpty {
            habits = HabitStore.defaultHabits
            seedSampleData()
            save()
        } else if completions.isEmpty {
            seedSampleData()
            save()
        }
    }

    private func seedSampleData() {
        let cal = Calendar.current
        let today = Date()
        guard let start = cal.date(byAdding: .day, value: -70, to: today) else { return }

        // Roughly mirrors the rates shown in the reference example (Walk/Swim/Stand
        // near-perfect, Yoga/Stretch lower).
        let rates: [Double] = [0.9, 0.55, 1.0, 0.4, 0.95, 0.85, 0.75, 0.8]

        var result: [String: Set<UUID>] = [:]
        var date = start
        while date <= today {
            let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 0
            var set: Set<UUID> = []
            for (index, habit) in habits.enumerated() {
                let rate = index < rates.count ? rates[index] : 0.7
                // Deterministic pseudo-random 0..99 from the day/habit combo.
                let pseudoRandom = ((dayOfYear &* 9301 &+ index &* 49297) &+ 233280) % 100
                if Double(pseudoRandom) < rate * 100 {
                    set.insert(habit.id)
                }
            }
            result[key(for: date)] = set
            guard let next = cal.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        completions = result
    }

    // MARK: Completion

    func key(for date: Date) -> String {
        HabitStore.dateFormatter.string(from: date)
    }

    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        completions[key(for: date)]?.contains(habit.id) ?? false
    }

    func toggle(_ habit: Habit, on date: Date) {
        let k = key(for: date)
        var set = completions[k] ?? []
        if set.contains(habit.id) {
            set.remove(habit.id)
        } else {
            set.insert(habit.id)
        }
        completions[k] = set
        save()
    }

    // MARK: Habit CRUD

    func addHabit(emoji: String, name: String, colorHex: String) {
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
        let finalEmoji = trimmedEmoji.isEmpty ? "⭐" : String(trimmedEmoji.prefix(2))
        habits.append(Habit(emoji: finalEmoji, name: name, colorHex: colorHex))
        save()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        for (k, var set) in completions where set.contains(habit.id) {
            set.remove(habit.id)
            completions[k] = set
        }
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: Stats

    func completedCount(for habit: Habit, in dates: [Date]) -> Int {
        dates.filter { isCompleted(habit, on: $0) }.count
    }

    func percent(for habit: Habit, in dates: [Date]) -> Double {
        guard !dates.isEmpty else { return 0 }
        return Double(completedCount(for: habit, in: dates)) / Double(dates.count) * 100
    }

    /// Longest run of consecutive completed days for a habit within `dates` (assumed chronological).
    func longestStreak(for habit: Habit, in dates: [Date]) -> Int {
        var best = 0
        var current = 0
        for date in dates {
            if isCompleted(habit, on: date) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    func totalDone(in dates: [Date]) -> Int {
        dates.reduce(0) { $0 + (completions[key(for: $1)]?.count ?? 0) }
    }

    func metPercent(in dates: [Date]) -> Double {
        guard !habits.isEmpty, !dates.isEmpty else { return 0 }
        let possible = habits.count * dates.count
        guard possible > 0 else { return 0 }
        return Double(totalDone(in: dates)) / Double(possible) * 100
    }

    /// Weekday label with the most total check-ins across all habits, within `dates`.
    func bestDayLabel(in dates: [Date]) -> String? {
        let cal = Calendar.current
        var counts: [Int: Int] = [:]
        for date in dates {
            let count = completions[key(for: date)]?.count ?? 0
            guard count > 0 else { continue }
            let weekday = cal.component(.weekday, from: date)
            counts[weekday, default: 0] += count
        }
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        let symbols = cal.shortWeekdaySymbols
        return symbols[(best.key - 1) % 7]
    }

    // MARK: Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: habitsKey)
        }
        let encodable = completions.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encodable) {
            UserDefaults.standard.set(data, forKey: completionsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
        if let data = UserDefaults.standard.data(forKey: completionsKey),
           let decoded = try? JSONDecoder().decode([String: [UUID]].self, from: data) {
            completions = decoded.mapValues { Set($0) }
        }
    }
}
