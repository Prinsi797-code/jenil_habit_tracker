//
//  DailyPlannerProvider.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 27/07/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct DailyPlannerEntry: TimelineEntry {
    let date: Date
    let data: DailyPlannerWidgetData
}

// MARK: - Provider

struct DailyPlannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyPlannerEntry {
        DailyPlannerEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyPlannerEntry) -> Void) {
        let data = context.isPreview ? .placeholder : WidgetDataStore.load()
        completion(DailyPlannerEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyPlannerEntry>) -> Void) {
        let entry = DailyPlannerEntry(date: Date(), data: WidgetDataStore.load())

        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
