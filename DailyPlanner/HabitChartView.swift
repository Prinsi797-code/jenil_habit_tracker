import SwiftUI
import Charts

struct HabitChartView: View {
    let habit: HabitTask
    @State private var chartData: [ChartDataPoint] = []
    
    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past 7 Days")
                .font(.headline)
                .foregroundColor(Color(.secondaryLabel))
            
            Chart(chartData) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(habit.accentColor.gradient)
                .cornerRadius(4)
                
                RuleMark(y: .value("Goal", habit.goal))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday())
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Generate past 7 days
        var dates: [Date] = []
        for i in (0..<7).reversed() {
            if let d = cal.date(byAdding: .day, value: -i, to: today) {
                dates.append(d)
            }
        }
        
        let entries = HabitHistoryStore.entries(
            from: dates.first ?? today,
            to: dates.last ?? today,
            titles: [habit.name]
        )
        
        chartData = dates.map { date in
            let match = entries.first { cal.isDate($0.date, inSameDayAs: date) }
            return ChartDataPoint(date: date, value: match?.value ?? 0.0)
        }
    }
}
