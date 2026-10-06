//
//  MoodRecordsListView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 03/08/26.
//

import SwiftUI

struct MoodRecordsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var allEntries: [MoodEntry] = []
    @State private var searchText: String = ""
    
    // MARK: - Mood helper enum (local, matches MoodsView)
    
    private enum MoodInfo: String, CaseIterable {
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
        
        init?(from rawValue: String) {
            // Try capitalized first, then exact match
            if let match = MoodInfo(rawValue: rawValue.capitalized) {
                self = match
            } else if let match = MoodInfo(rawValue: rawValue) {
                self = match
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Palette
    
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    private let pageBackground = Color(.systemGroupedBackground)
    private let accent = Color(red: 0.95, green: 0.42, blue: 0.42)
    
    // MARK: - Filtered & grouped data
    
    private var filteredEntries: [MoodEntry] {
        let sorted = allEntries.sorted { $0.date > $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter { entry in
            entry.moodRawValue.localizedCaseInsensitiveContains(searchText) ||
            entry.note.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Group entries by month (e.g. "August 2026")
    private var groupedEntries: [(month: String, entries: [MoodEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            formatter.string(from: entry.date)
        }
        
        // Sort groups by the date of the first entry (most recent first)
        return grouped
            .map { (month: $0.key, entries: $0.value) }
            .sorted { lhs, rhs in
                guard let lDate = lhs.entries.first?.date,
                      let rDate = rhs.entries.first?.date else { return false }
                return lDate > rDate
            }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            if allEntries.isEmpty {
                emptyState
            } else {
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                List {
                    ForEach(groupedEntries, id: \.month) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                recordRow(entry)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                            }
                            .onDelete { offsets in
                                deleteEntries(in: group.entries, at: offsets)
                            }
                        } header: {
                            Text(group.month)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(inkPrimary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            
            // Native Ad pinned at bottom
            if RemoteConfigManager.shared.nativeMoodRecordFlag == 1 {
                NativeAdContainerView(adUnitID: RemoteConfigManager.shared.nativeMoodRecordID)
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .onAppear {
            allEntries = MoodStore.loadAll()
            print("--- MoodRecordsListView ---")
            print("nativeMoodRecordFlag: \(RemoteConfigManager.shared.nativeMoodRecordFlag)")
            print("nativeMoodRecordID: \(RemoteConfigManager.shared.nativeMoodRecordID)")
        }
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer(minLength: 8)
            
            Text("Mood Records")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 8)
            
            // Placeholder for alignment symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(pageBackground)
    }
    
    // MARK: - Search bar
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(inkMuted)
            
            TextField("Search moods or notes...", text: $searchText)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(inkPrimary)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(inkMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }
    
    // MARK: - Empty state
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "face.dashed")
                .font(.system(size: 56))
                .foregroundColor(inkMuted)
            Text("No mood records yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(inkSecondary)
            Text("Start tracking your mood to see\nyour records here.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(inkMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    

    
    // MARK: - Record row
    
    private func recordRow(_ entry: MoodEntry) -> some View {
        let mood = MoodInfo(from: entry.moodRawValue)
        let cal = Calendar.current
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "en_US")
        weekdayFormatter.dateFormat = "EEE"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        return HStack(spacing: 14) {
            // Day number + weekday
            VStack(spacing: 0) {
                Text("\(cal.component(.day, from: entry.date))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                Text(weekdayFormatter.string(from: entry.date).uppercased())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
            }
            .frame(width: 44)
            
            // Mood icon
            if let mood = mood {
                Image(mood.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            } else {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 44, height: 44)
            }
            
            // Mood label + note
            VStack(alignment: .leading, spacing: 3) {
                Text(mood?.rawValue ?? entry.moodRawValue.capitalized)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(mood?.color ?? inkPrimary)
                
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(inkSecondary)
                        .lineLimit(2)
                } else {
                    Text(dateFormatter.string(from: entry.date))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(inkMuted)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())

    }
    
    // MARK: - Delete
    
    private func deleteEntries(in entries: [MoodEntry], at offsets: IndexSet) {
        for index in offsets {
            MoodStore.delete(id: entries[index].id)
        }
        withAnimation {
            allEntries = MoodStore.loadAll()
        }
    }
}

#Preview {
    MoodRecordsListView()
}
