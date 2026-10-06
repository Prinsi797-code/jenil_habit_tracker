import SwiftUI
 
// MARK: - Model
 
struct HabitIdea: Identifiable {
    let id = UUID()
    let systemImage: String
    let iconColor: Color
    let title: String
    let subtitle: String
}
 
// MARK: - Data
 
let habitIdeas: [HabitIdea] = [
    HabitIdea(systemImage: "figure.stand", iconColor: .purple, title: "Lose weight", subtitle: "Losing weight is not easy, but it's possible"),
    HabitIdea(systemImage: "banknote.fill", iconColor: .orange, title: "Become a Millionaire", subtitle: "Start now, start small, you could be a millionaire"),
    HabitIdea(systemImage: "waveform.path.ecg", iconColor: .teal, title: "Be healthy", subtitle: "A healthy life > a wealthy life"),
    HabitIdea(systemImage: "checkmark.circle.fill", iconColor: .blue, title: "Tiny habits", subtitle: "Small habits, big results"),
    HabitIdea(systemImage: "person.2.fill", iconColor: Color.defaultPrimary, title: "Be social", subtitle: "Be social in real life, be human"),
    HabitIdea(systemImage: "face.smiling.fill", iconColor: .orange, title: "Be positive", subtitle: "Positive people see the good things always"),
    HabitIdea(systemImage: "figure.strengthtraining.traditional", iconColor: .blue, title: "Gain muscle", subtitle: "You cannot change your face, but you can change your body"),
    HabitIdea(systemImage: "sparkles", iconColor: Color.defaultPrimary, title: "Skin Care", subtitle: "Kill the acne"),
    HabitIdea(systemImage: "text.bubble.fill", iconColor: .green, title: "Learning a language", subtitle: "Learning a language, learning a culture"),
    HabitIdea(systemImage: "timer", iconColor: .cyan, title: "Be productive", subtitle: "Work hard in a smart way"),
    HabitIdea(systemImage: "heart.circle.fill", iconColor: Color.defaultPrimary, title: "Be a good spouse", subtitle: "Love your wife/husband, you could be happier")
]
 
// MARK: - Card View
 
struct HabitIdeaCard: View {
    let idea: HabitIdea
 
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(idea.iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: idea.systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(idea.iconColor)
            }
 
            Text(idea.title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
 
            Text(idea.subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
}
 
// MARK: - Screen
 
struct HabitIdeaView: View {
    @Environment(\.dismiss) private var dismiss
 
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
 
    var body: some View {
        ZStack(alignment: .top) {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()
 
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(habitIdeas) { idea in
                        HabitIdeaCard(idea: idea)
                            .onTapGesture {
                                AnalyticsManager.shared.logHabitIdeaUsed()
                                // Handle selection
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack {
                Text("Habit Idea")
                    .font(.system(size: 20, weight: .bold))
 
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 14)
//            .background(Color(.systemBackground))
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
 
// MARK: - Preview
 
#Preview {
    HabitIdeaView()
}
