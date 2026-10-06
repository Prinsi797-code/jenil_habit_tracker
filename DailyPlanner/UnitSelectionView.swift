import SwiftUI

struct UnitItem: Identifiable {
    let id = UUID()
    let name: String
    let unit: String?
}

struct UnitSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUnit: String
    
    @State private var selectedCategory = "Activity"
    @State private var searchText = ""
    
    private let categories = ["Activity", "Nutrition Intake", "Mind", "Workout", "Other"]
    
    private let activityUnits: [UnitItem] = [
        UnitItem(name: "Active Energy", unit: nil),
        UnitItem(name: "Basal Energy", unit: nil),
        UnitItem(name: "Cycling Distance", unit: nil),
        UnitItem(name: "Flights Climbed", unit: "floors"),
        UnitItem(name: "Move Time", unit: "min"),
        UnitItem(name: "Stand Hours", unit: "hr"),
        UnitItem(name: "Stand Minutes", unit: "min"),
        UnitItem(name: "Steps", unit: "steps"),
        UnitItem(name: "Swimming Distance", unit: nil),
        UnitItem(name: "Walking + Running Distance", unit: nil)
    ]
    
    private let mindUnits: [UnitItem] = [
        UnitItem(name: "Exercise Minutes", unit: "min"),
        UnitItem(name: "Mindful Minutes", unit: "min"),
        UnitItem(name: "Sleep", unit: nil),
        UnitItem(name: "Time in Daylight", unit: "min")
    ]
    
    private let nutritionUnits: [UnitItem] = [
        UnitItem(name: "Calories", unit: "kcal"),
        UnitItem(name: "Protein", unit: "g"),
        UnitItem(name: "Carbohydrates", unit: "g"),
        UnitItem(name: "Fat", unit: "g"),
        UnitItem(name: "Water Intake (ml)", unit: "ml"),
        UnitItem(name: "Water Intake (L)", unit: "L")
    ]
    
    private let workoutUnits: [UnitItem] = [
        UnitItem(name: "Workout Time", unit: "min"),
        UnitItem(name: "Sets", unit: "sets"),
        UnitItem(name: "Repetitions", unit: "reps"),
        UnitItem(name: "Weight", unit: "kg"),
        UnitItem(name: "Distance", unit: "km")
    ]
    
    private let otherUnits: [UnitItem] = [
        UnitItem(name: "Count", unit: "count"),
        UnitItem(name: "Pages", unit: "pages"),
        UnitItem(name: "Chapters", unit: "chapters"),
        UnitItem(name: "Sessions", unit: "sessions")
    ]
    
    private let pageBackground = Color(.systemGroupedBackground)
    private let cardSurface = Color(.systemBackground)
    private let pinkAccent = Color(red: 1.0, green: 0.4, blue: 0.5)
    
    private var currentUnits: [UnitItem] {
        switch selectedCategory {
        case "Nutrition Intake": return nutritionUnits
        case "Mind": return mindUnits
        case "Workout": return workoutUnits
        case "Other": return otherUnits
        default: return activityUnits
        }
    }
    
    private var filteredUnits: [UnitItem] {
        let base = currentUnits
        if searchText.isEmpty {
            return base
        } else {
            return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                
                Spacer()
                
                Text("Unit")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            .background(
                                Capsule().fill(selectedCategory == category ? AnyShapeStyle(pinkAccent) : AnyShapeStyle(Color(.systemBackground)))
                            )                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            
            // List of Units
            ScrollView {
                VStack(spacing: 0) {
                    if filteredUnits.isEmpty {
                        Text("No units found")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 30)
                    } else {
                        ForEach(filteredUnits) { item in
                            let isSelected = selectedUnit == (item.unit ?? item.name)
                            
                            VStack(spacing: 0) {
                                Button(action: {
                                    selectedUnit = item.unit ?? item.name
                                    dismiss()
                                }) {
                                    HStack {
                                        Text(item.name)
                                            .foregroundColor(.primary)
                                            .font(.system(size: 16, design: .rounded))
                                        
                                        Spacer()
                                        
                                        if let unitStr = item.unit {
                                            Text(unitStr)
                                                .foregroundColor(isSelected ? .primary : .secondary)
                                                .font(.system(size: 15, design: .rounded))
                                        }
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(pinkAccent)
                                                .padding(.leading, 6)
                                        } else if item.unit == nil {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(.tertiaryLabel))
                                        }
                                    }
                                    .padding(.vertical, 16)
                                }
                                
                                if item.id != filteredUnits.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(cardSurface))
            }
            
            // Search Bar at Bottom
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.secondaryLabel))
                TextField("Search", text: $searchText)
                    .font(.system(size: 16, design: .rounded))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color(.systemBackground)))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
