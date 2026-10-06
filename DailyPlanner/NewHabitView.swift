//
//  NewHabitView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 24/07/26.
//

import SwiftUI

struct NewHabitView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var onSave: ((String, String, Double, String, String, Date?, String, String, String, String, Int) -> Void)?

    // MARK: - Computed Properties
    
    private var currentHabits: [HabitItem] {
        habitCategories.first(where: { $0.name == selectedCategory })?.items ?? []
    }

    @State private var selectedCategory: String = "Popular"
    @State private var favorited: Set<UUID> = []
    @State private var selectedHabit: HabitItem?

    /// Drives navigation into the "Custom Habit" creation flow (a blank HabitDetailView).
    @State private var showCustomHabit: Bool = false

    /// Drives navigation into the "Habit Idea" screen (tapped via the top-right bag icon).
    @State private var showHabitIdea: Bool = false

    @EnvironmentObject private var themeManager: AppThemeManager

    // MARK: - Palette (mirrors ContentView's theme)
    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private var pageBackground: Color {
        colorScheme == .dark ? (Color(hex: "#1A1919") ?? Color.black) : Color(.systemGroupedBackground)
    }

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    topBar
                    categoryPills
                    habitList
                }
                .background(pageBackground.ignoresSafeArea())

                customHabitButton
                    .padding(.bottom, 10)
            }
            .navigationDestination(item: $selectedHabit) { habit in
                HabitDetailView(emoji: habit.emoji, name: habit.name, onSave: { emoji, name, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType in
                    onSave?(emoji, name, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType)
                    dismiss()
                })
            }
            .navigationDestination(isPresented: $showCustomHabit) {
                HabitDetailView(emoji: "⭐", name: "", isCustom: true, onSave: { emoji, name, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType in
                    onSave?(emoji, name, goal, unit, colorHex, endDate, goalPeriod, habitType, taskDays, timeRange, chartType)
                    dismiss()
                })
            }
        }
        .fullScreenCover(isPresented: $showHabitIdea) {
            HabitIdeaView()
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(inkPrimary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("New Habit")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(inkPrimary)

            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
//            Button(action: { showHabitIdea = true }) {
//                Image(systemName: "bag.fill")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(width: 30, height: 30)
//                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(pinkGradient))
//            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Category pills
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(habitCategories, id: \.name) { category in
                    categoryPill(category)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 18)
    }

    private func categoryPill(_ category: HabitCategory) -> some View {
        let isSelected = category.name == selectedCategory

        return HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
            Text(category.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .foregroundColor(isSelected ? .white : inkPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(isSelected ? AnyShapeStyle(pinkGradient) : AnyShapeStyle(Color(.systemBackground)))
        )
        .overlay(
            Capsule().stroke(Color.black.opacity(isSelected ? 0 : 0.06), lineWidth: 1)
        )
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category.name
            }
        }
    }

    // MARK: - Habit list
    private var habitList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(currentHabits) { habit in
                    habitRow(habit)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 140)
        }
    }

    private func habitRow(_ habit: HabitItem) -> some View {
        let isFavorited = favorited.contains(habit.id)

        return HStack(spacing: 10) {
            Button(action: { selectedHabit = habit }) {
                HStack(spacing: 10) {
                    Text(habit.emoji)
                        .font(.system(size: 24))

                    Text(habit.name)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(inkPrimary)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if habit.hasFavorite {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        if isFavorited {
                            favorited.remove(habit.id)
                        } else {
                            favorited.insert(habit.id)
                        }
                    }
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(pinkRed)
                        .frame(width: 30, height: 30)
                }
            }

            Button(action: {
                selectedHabit = habit
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(inkPrimary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Custom habit button

    private var customHabitButton: some View {
        Button(action: {
            showCustomHabit = true
        }) {
            Text("Custom Habit")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
                .background(Capsule().fill(pinkGradient))
                .shadow(color: pinkRed.opacity(0.35), radius: 10, x: 0, y: 6)
        }
    }
}

#Preview {
    NewHabitView()
}
