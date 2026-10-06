//
//  ContentView+Widget.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 27/07/26.
//

import WidgetKit

extension ContentView {
    
    func publishToWidget() {
        let today = days[ContentView.todayIndex(homeWeekBar: homeWeekBar)]
        
        let cal = Calendar.current
        
        let summaries = tasks
            .filter { !$0.isHidden }
            .map { task in
                HabitSummary(
                    id: task.id,
                    emoji: task.emoji,
                    title: task.title,
                    fraction: Double(task.fraction),
                    colorHex: task.fillColor.hexString,
                    streakDays: task.streakDays,
                    isSkipped: task.isSkipped
                )
            }
        
        let data = DailyPlannerWidgetData(
            dayLabel: DateFormatter().shortWeekdaySymbols[cal.component(.weekday, from: today.fullDate) - 1].uppercased(),
            dayNumber: today.date,
            habits: summaries,
            backgroundHex: nil,
            isTransparentBackground: false,
            fontColorHex: nil,
            isDarkAppearance: false
        )
        
        WidgetDataStore.save(data)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

import SwiftUI
import UIKit

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
