import SwiftUI

// MARK: - Day strip model
struct DayItem: Identifiable {
    let id = UUID()
    let label: String
    let date: Int
    let fullDate: Date
    var progress: CGFloat = 0
}

// MARK: - Task model (Run, Meditation, Drink water, Sleep, Walk, ...)
struct AppHabitTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var emoji: String
    var title: String
    var current: Double
    var goal: Double
    var unit: String
    var streakDays: Int
    var stepAmount: Double = 1
    
    var colorHex: String
    var isCompleted: Bool = false
    var isSkipped: Bool = false
    var isHidden: Bool = false
    var memoText: String = ""
    var mood: String? = nil
    var endDate: Date? = nil
    var goalPeriod: String = "Day-Long"
    var habitType: String = "Build"
    var taskDays: String = "Every Day"
    var timeRange: String = "Anytime"
    var chartType: Int = 0

    var fillColor: Color { Color(hex: colorHex) }

    var progressText: String {
        func fmt(_ v: Double) -> String {
            String(Int(v.rounded()))
        }
        return "\(fmt(current))/\(fmt(goal)) \(unit)"
    }

    var fraction: CGFloat {
        guard goal > 0 else { return 0 }
        return CGFloat(min(max(current / goal, 0), 1))
    }

    var baseColor: Color { fillColor.opacity(0.16) }

    var textColor: Color { fraction >= 1.0 ? .white : Color(.label) }
}
