import SwiftUI
import Lottie

struct CheckInMethodOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("checkInMethod") private var checkInMethod: String = "Swipe right to check in"
    @AppStorage("hasSeenCheckInMethodOnboarding") private var hasSeenCheckInMethodOnboarding: Bool = false
    
    // Theme colors
    private let accentColor = Color(red: 0.99, green: 0.35, blue: 0.53) // matches the screenshot pink
    private let pageBackground = Color(red: 1.0, green: 0.93, blue: 0.93)
    
    var body: some View {
        VStack(spacing: 10) {
            // Header
            Text("Check-in Method")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding(.top, 40)
            
            Text("Please choose your preferred check-in method.")
                .font(.system(size: 16))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.top, 16)
                .padding(.bottom, 25)
            
            // Cards
            HStack(spacing: 15) {
                // Swipe Option
                methodCard(
                    title: "Swipe right to check in",
                    isSelected: checkInMethod == "Swipe right to check in",
                    content: {
                        Image("img_swipeMethod")
                            .resizable()
                            .scaledToFit()
                    },
                    action: {
                        withAnimation { checkInMethod = "Swipe right to check in" }
                    }
                )
                
                // Tap Option
                methodCard(
                    title: "Tap to check in",
                    isSelected: checkInMethod == "Tap to check in",
                    content: {
                        Image("img_tapMethod")
                            .resizable()
                            .scaledToFit()
                    },
                    action: {
                        withAnimation { checkInMethod = "Tap to check in" }
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 5)
            
            Spacer()
            
            // Confirm Button
            Button(action: {
                hasSeenCheckInMethodOnboarding = true
                dismiss()
            }) {
                Text("Confirm")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 170, height: 40)
                    .background(Capsule().fill(accentColor))
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.bottom, 10)
            
            // Footnote
            Text("In app \"setting\" - \"more setting\" - \"Check-in method\", you can change between \"Tap\" or \"Swipe\" mode")
                .font(.system(size: 10))
                .frame(height: 40)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .padding(.horizontal, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(pageBackground.ignoresSafeArea())
    }
    
    @ViewBuilder
    private func methodCard<Content: View>(title: String, isSelected: Bool, @ViewBuilder content: @escaping () -> Content, action: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            // Screen Mockup
            content()
                .frame(width: 140, height: 240)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.75),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .contentShape(Rectangle())
                .onTapGesture { action() }
            
            // Label & Radio Button
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Circle()
                    .strokeBorder(isSelected ? accentColor : Color.gray.opacity(0.5), lineWidth: 2)
                    .background(Circle().fill(isSelected ? accentColor : Color.clear))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .onTapGesture { action() }
        }
    }
    
}
