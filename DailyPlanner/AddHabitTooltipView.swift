import SwiftUI

struct DownwardTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct AddHabitTooltipView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Add New Task")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                
                Text("Tap here to add a new task or habit to your daily routine.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color(.secondaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Text("Got it")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(themeManager.horizontalGradient)
                            )
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
            )
            
            DownwardTriangle()
                .fill(Color(UIColor.systemBackground))
                .frame(width: 24, height: 12)
                .padding(.leading, 50) // Adjust to point to the first tab bar item
        }
        .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        AddHabitTooltipView(onDismiss: {})
            .padding()
            .environmentObject(AppThemeManager())
    }
}
