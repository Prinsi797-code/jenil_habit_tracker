//
//  ExportOptionView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI

private extension VerticalAlignment {
    private struct CapsuleCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }
    static let capsuleCenter = VerticalAlignment(CapsuleCenter.self)
}

struct ExportOptionView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager

    let habits: [HabitSummary]

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedHabits: Set<String>
    @State private var activeDatePicker: DatePickerTarget? = nil
    @State private var exportedFile: IdentifiableURL? = nil
    @State private var showPremiumUpgrade: Bool = false
    
    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private struct IdentifiableURL: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    var onExport: ((Date, Date, Set<String>) -> Void)? = nil

    init(
        habits: [HabitSummary],
        startDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now,
        endDate: Date = .now,
        onExport: ((Date, Date, Set<String>) -> Void)? = nil
    ) {
        self.habits = habits
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
        _selectedHabits = State(initialValue: Set(habits.map(\.title)))
        self.onExport = onExport
    }

    private enum DatePickerTarget: Identifiable {
        case start
        case end
        var id: Int { self == .start ? 0 : 1 }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                dateRangeCard
                habitsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.pageSurface.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interExportID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interExport")
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeDatePicker) { target in
            datePickerSheet(for: target)
        }
        .sheet(item: $exportedFile) { wrapped in
            ShareSheet(items: [wrapped.url])
        }
        .fullScreenCover(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: {
                InterstitialAdManager.shared.showAdIfAppropriate(
                    flag: RemoteConfigManager.shared.interExportFlag,
                    adKey: "interExport",
                    adUnitID: RemoteConfigManager.shared.interExportID
                )
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("Export Option")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                if isPremium {
                    let entries = HabitHistoryStore.entries(from: startDate, to: endDate, titles: selectedHabits)
                    if let url = HabitCSVExporter.writeTempFile(entries: entries, start: startDate, end: endDate) {
                        exportedFile = IdentifiableURL(url: url)
                        AnalyticsManager.shared.logDataExported()
                    }
                    onExport?(startDate, endDate, selectedHabits)
                } else {
                    showPremiumUpgrade = true
                }
            }) {
                Text("Export")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 5)
                    .background(themeManager.horizontalGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.pageSurface)
    }

    // MARK: - Date range card

    private var dateRangeCard: some View {
        HStack(alignment: .capsuleCenter, spacing: 0) {
            dateColumn(title: "Start", date: startDate, isEmphasized: true) {
                activeDatePicker = .start
            }

            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity)
                .alignmentGuide(.capsuleCenter) { d in d[VerticalAlignment.center] }

            dateColumn(title: "End", date: endDate, isEmphasized: false) {
                activeDatePicker = .end
            }
        }
        .padding(20)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private func dateColumn(
        title: String,
        date: Date,
        isEmphasized: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.primary)

            Button(action: onTap) {
                Text(Self.dateFormatter.string(from: date))
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 90)
                    .foregroundColor(isEmphasized ? .white : .primary)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isEmphasized {
                                themeManager.horizontalGradient
                            } else {
                                Color.gray.opacity(0.15)
                            }
                        }
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .alignmentGuide(.capsuleCenter) { d in d[VerticalAlignment.center] }
        }
        .frame(maxWidth: .infinity)
    }

    private func datePickerSheet(for target: DatePickerTarget) -> some View {
        let binding: Binding<Date> = target == .start ? $startDate : $endDate

        return NavigationStack {
            DatePicker(
                "",
                selection: binding,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(themeManager.primaryColor)
            .padding()
            .navigationTitle(target == .start ? "Start Date" : "End Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { activeDatePicker = nil }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Habits card

    private var habitsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: toggleSelectAll) {
                    Text(selectedHabits.count == habits.count ? "Deselect All" : "Select All")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 12)

            ForEach(habits) { habit in
                habitRow(habit)
            }
            .padding(.bottom, 8)
        }
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private func habitRow(_ habit: HabitSummary) -> some View {
        Button(action: { toggle(habit.title) }) {
            HStack(spacing: 14) {
                Text(habit.emoji)
                    .font(.system(size: 22))

                Text(habit.title)
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                checkmark(isSelected: selectedHabits.contains(habit.title))
            }
            .padding(.horizontal, 22)
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }

    private func checkmark(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? themeManager.primaryColor : Color.gray.opacity(0.4), lineWidth: 1.5)
                .background(Circle().fill(isSelected ? themeManager.primaryColor : Color.clear))
                .frame(width: 26, height: 26)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Selection helpers

    private func toggle(_ name: String) {
        if selectedHabits.contains(name) {
            selectedHabits.remove(name)
        } else {
            selectedHabits.insert(name)
        }
    }

    private func toggleSelectAll() {
        if selectedHabits.count == habits.count {
            selectedHabits.removeAll()
        } else {
            selectedHabits = Set(habits.map(\.title))
        }
    }
}

#Preview {
    NavigationStack {
        ExportOptionView(habits: [])
    }
}
