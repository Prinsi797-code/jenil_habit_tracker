//
//  OnboardingView.swift
//  DailyPlanner
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var currentStep = 0
    @State private var showPaywall = false
    @EnvironmentObject private var themeManager: AppThemeManager
    
    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    private let steps = [
        OnboardingStep(
            icon: "checklist.checked",
            title: "Build Better Habits",
            description: "Track your daily tasks and watch your streaks grow every day."
        ),
        OnboardingStep(
            icon: "face.smiling",
            title: "Track Your Mood",
            description: "Reflect on your day with daily check-ins and understand your emotions."
        ),
        OnboardingStep(
            icon: "paintpalette.fill",
            title: "Beautiful Widgets",
            description: "Customize your home screen with exclusive themes and beautiful aesthetics."
        ),
        OnboardingStep(
            icon: "bell.badge.fill",
            title: "Stay on Track",
            description: "Enable notifications so we can gently remind you about your daily habits."
        )
    ]

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // Reusing the premium background for a nice aesthetic touch
            Image("img_onboarding")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.8)

            VStack {
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        OnboardingStepView(step: steps[index], gradient: pinkGradient)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Spacer()
                
                Button(action: handleNext) {
                    Text(currentStep == steps.count - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pinkGradient)
                        .clipShape(Capsule())
                        .shadow(color: themeManager.primaryColor.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Placeholder for spacing to match the standard layout padding at the bottom
                Spacer().frame(height: 38)
            }
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            hasSeenOnboarding = true
            AnalyticsManager.shared.logOnboardingCompleted()
        }) {
            PremiumUpgradeView()
                .environmentObject(themeManager)
        }
    }
    
    private func handleNext() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Last step: finish onboarding
            finishOnboarding()
        }
    }
    
    private func finishOnboarding() {
        showPaywall = true
    }
}

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: step.icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(gradient)
            }
            
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding(.bottom, 60)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppThemeManager())
}
