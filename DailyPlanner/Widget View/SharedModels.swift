//
//  SharedModels.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 27/07/26.
//

import Foundation
import SwiftUI
import ActivityKit

// MARK: - Lightweight snapshot of a habit, safe to serialize into the widget's shared store.

struct HabitSummary: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var emoji: String
    var title: String
    var fraction: Double
    var colorHex: String
    var streakDays: Int
    var isSkipped: Bool
    var weekCompletion: [Bool] = [false, false, false, false, false, false, false]
    var monthCompletionDays: [Int] = []

    var color: Color { Color(hex: colorHex) }
}

/// Everything the widget needs to render: today's habits plus the chosen theme.
struct DailyPlannerWidgetData: Codable, Equatable {
    var dayLabel: String
    var dayNumber: Int
    var habits: [HabitSummary]
    var backgroundHex: String?
    var isTransparentBackground: Bool
    var fontColorHex: String?
    var isDarkAppearance: Bool
    var weekdayIndex: Int = 0

    static var placeholder: DailyPlannerWidgetData {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let dayNumber = cal.component(.day, from: today)
        let dayLabel = DateFormatter().shortWeekdaySymbols[weekday - 1].uppercased()
        
        return DailyPlannerWidgetData(
            dayLabel: dayLabel,
            dayNumber: dayNumber,
            habits: [
                HabitSummary(id: UUID(), emoji: "🏃🏻‍♂️", title: "Run", fraction: 0.72, colorHex: "4CB86B", streakDays: 1, isSkipped: false, weekCompletion: [true, true, false, false, true, true, true]),
                HabitSummary(id: UUID(), emoji: "🧘", title: "Meditation", fraction: 0.55, colorHex: "8C99C7", streakDays: 1, isSkipped: false, weekCompletion: [true, true, false, false, true, true, true]),
                HabitSummary(id: UUID(), emoji: "💧", title: "Drink water", fraction: 0.40, colorHex: "38ADDB", streakDays: 0, isSkipped: false, weekCompletion: [true, true, false, false, true, true, true]),
                HabitSummary(id: UUID(), emoji: "🛏️", title: "Sleep", fraction: 1.0, colorHex: "6B52D9", streakDays: 2, isSkipped: false, weekCompletion: [true, true, false, false, true, true, true]),
                HabitSummary(id: UUID(), emoji: "📖", title: "Read", fraction: 0.30, colorHex: "D98C3A", streakDays: 0, isSkipped: false, weekCompletion: [true, true, false, false, true, true, true]),
                HabitSummary(id: UUID(), emoji: "🥗", title: "Eat veggies", fraction: 0.85, colorHex: "6BA83A", streakDays: 3, isSkipped: false, weekCompletion: [true, true, false, false, true, true, true])
            ],
            backgroundHex: nil,
            isTransparentBackground: false,
            fontColorHex: nil,
            isDarkAppearance: false,
            weekdayIndex: 0
        )
    }
}

// MARK: - App Group backed store

enum WidgetDataStore {
    static let appGroupID = "group.com.hevin.habitmaster"
    private static let storageKey = "dailyPlannerWidgetData"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ data: DailyPlannerWidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: storageKey)
    }

    static func load() -> DailyPlannerWidgetData {
        guard let raw = defaults?.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(DailyPlannerWidgetData.self, from: raw)
        else {
            return .placeholder
        }
        return decoded
    }
}

// MARK: - Per-day habit log (feeds CSV export in ExportOptionView)

struct HabitLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var habitTitle: String
    var date: Date          // normalized to start-of-day
    var value: Double
    var unit: String
    var memo: String        // combined mood + memo text, e.g. "😀 Done"
    var tag: String = ""            // reserved for future use
    var habitType: String = "Build" // reserved for future habit categories
}

enum HabitHistoryStore {
    private static let storageKey = "dailyPlannerHabitHistory"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetDataStore.appGroupID)
    }

    static func loadAll() -> [HabitLogEntry] {
        guard let raw = defaults?.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HabitLogEntry].self, from: raw)
        else { return [] }
        return decoded
    }

    private static func saveAll(_ entries: [HabitLogEntry]) {
        guard let encoded = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(encoded, forKey: storageKey)
    }

    /// Upserts today's entry for a given habit (one entry per habit per calendar day).
    static func upsert(habitTitle: String, date: Date, value: Double, unit: String, memo: String) {
        var entries = loadAll()
        let day = Calendar.current.startOfDay(for: date)

        if let idx = entries.firstIndex(where: {
            $0.habitTitle == habitTitle && Calendar.current.isDate($0.date, inSameDayAs: day)
        }) {
            entries[idx].value = value
            entries[idx].unit = unit
            entries[idx].memo = memo
        } else {
            entries.append(
                HabitLogEntry(id: UUID(), habitTitle: habitTitle, date: day, value: value, unit: unit, memo: memo)
            )
        }
        saveAll(entries)
    }

    /// Entries within [start, end] (inclusive, by calendar day), restricted to the given habit titles.
    static func entries(from start: Date, to end: Date, titles: Set<String>) -> [HabitLogEntry] {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        return loadAll()
            .filter { titles.contains($0.habitTitle) }
            .filter { entry in
                let d = cal.startOfDay(for: entry.date)
                return d >= startDay && d <= endDay
            }
            .sorted {
                $0.habitTitle != $1.habitTitle ? $0.habitTitle < $1.habitTitle : $0.date < $1.date
            }
    }
    
    static func deleteAll(for habitTitle: String) {
        var entries = loadAll()
        entries.removeAll { $0.habitTitle == habitTitle }
        saveAll(entries)
    }
    
    static func deleteAll() {
        saveAll([])
    }
}

// MARK: - Mood Storage

struct MoodEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date // normalized to start-of-day
    var moodRawValue: String // MoodKind rawValue
    var note: String
}

enum MoodStore {
    private static let storageKey = "dailyPlannerMoodHistory"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetDataStore.appGroupID)
    }

    static func loadAll() -> [MoodEntry] {
        guard let raw = defaults?.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MoodEntry].self, from: raw)
        else { return [] }
        return decoded
    }

    private static func saveAll(_ entries: [MoodEntry]) {
        guard let encoded = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(encoded, forKey: storageKey)
    }

    /// Save a new mood entry, overwriting today's entry if one already exists.
    static func save(_ entry: MoodEntry) {
        var entries = loadAll()
        let day = Calendar.current.startOfDay(for: entry.date)

        if let idx = entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            entries[idx].moodRawValue = entry.moodRawValue
            entries[idx].note = entry.note
        } else {
            let normalizedEntry = MoodEntry(id: entry.id, date: day, moodRawValue: entry.moodRawValue, note: entry.note)
            entries.append(normalizedEntry)
        }
        saveAll(entries)
    }

    static func entryForToday() -> MoodEntry? {
        let entries = loadAll()
        let today = Calendar.current.startOfDay(for: Date())
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    static func delete(id: UUID) {
        var entries = loadAll()
        entries.removeAll { $0.id == id }
        saveAll(entries)
    }
    
    static func deleteAll() {
        saveAll([])
    }
}

// MARK: - CSV export matching the "Habit,Date,Value,Unit,Memo,Tag,Habit Type" format

enum HabitCSVExporter {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f
    }()

    static func makeCSV(entries: [HabitLogEntry]) -> String {
        var lines = ["Habit,Date,Value,Unit,Memo,Tag,Habit Type"]
        for entry in entries {
            let dateStr = dateFormatter.string(from: entry.date)
            let valueStr = entry.value == entry.value.rounded()
                ? String(Int(entry.value))
                : String(entry.value)
            let fields = [entry.habitTitle, dateStr, valueStr, entry.unit, entry.memo, entry.tag, entry.habitType]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    /// Writes the CSV to a temp file named like "20260724_20260729_Habit.csv" and returns its URL.
    static func writeTempFile(entries: [HabitLogEntry], start: Date, end: Date) -> URL? {
        let csv = makeCSV(entries: entries)
        let filename = "\(filenameDateFormatter.string(from: start))_\(filenameDateFormatter.string(from: end))_Habit.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "%02X%02X%02X",
            Int(r * 255), Int(g * 255), Int(b * 255)
        )
    }
}

// MARK: - Live Activity Attributes

struct DailyPlannerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state of the Live Activity
        var activeTimerHabit: String?
        var timerEndTime: Date?
        
        var selectedHabits: [HabitSummary]
    }

    // Static data (e.g. general info)
    var name: String
}
