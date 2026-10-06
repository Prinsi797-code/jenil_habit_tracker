//
//  MoodsViewModels.swift
//  DailyPlanner
//

import SwiftUI

enum MoodType: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case neutral = "Neutral"
    case poor = "Poor"
    case bad = "Bad"
    case awful = "Awful"
    case great = "Great"
    
    var imageName: String {
        switch self {
        case .excellent: return "ic_excellent"
        case .great:     return "ic_great"
        case .good:      return "ic_good"
        case .neutral:   return "ic_neutral"
        case .poor:      return "ic_poor"
        case .bad:       return "ic_bad"
        case .awful:     return "ic_awful"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return Color(red: 0.99, green: 0.68, blue: 0.35)
        case .great: return Color(red: 0.99, green: 0.68, blue: 0.35)
        case .good: return Color(red: 0.55, green: 0.80, blue: 0.58)
        case .neutral: return Color(red: 0.55, green: 0.72, blue: 0.93)
        case .poor: return Color(red: 0.55, green: 0.72, blue: 0.93)
        case .bad: return Color(red: 0.65, green: 0.60, blue: 0.85)
        case .awful: return Color(red: 0.90, green: 0.50, blue: 0.50)
        }
    }
    
    var rank: Double {
        switch self {
        case .awful: return 0
        case .bad: return 1
        case .poor: return 2
        case .neutral: return 3
        case .good: return 4
        case .great: return 5
        case .excellent: return 6
        }
    }
}

/// Which range mode a card's toggle is currently in.
enum RangeMode: CaseIterable {
    case week
    case month
    
    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}

struct MoodRecord: Identifiable {
    let id = UUID()
    let day: Int
    let weekday: String
    let mood: MoodType
    let note: String
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let isCurrentMonth: Bool
    let mood: MoodType?
    let hasNote: Bool
    let isToday: Bool
}

/// A single plotted point on the trend chart. `slotIndex` is the
/// x-axis position — a weekday (0=Mon...6=Sun) in week mode, or a
/// week-of-month index (0=W1, 1=W2, ...) in month mode.
struct TrendPoint: Identifiable {
    let id = UUID()
    let slotIndex: Int
    let mood: MoodType
}
