//
//  MoodCheckInView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 29/07/26.
//

import SwiftUI

// MARK: - Mood model

enum MoodKind: String, CaseIterable, Identifiable {
    case awful, excellent, bad, great, poor, neutral, good
    var id: String { rawValue }

    var label: String {
        switch self {
        case .awful: return "Awful"
        case .excellent: return "Excellent"
        case .bad: return "Bad"
        case .great: return "Great"
        case .poor: return "Poor"
        case .neutral: return "Neutral"
        case .good: return "Good"
        }
    }

    var imageName: String {
        switch self {
        case .awful: return "ic_awful"
        case .excellent: return "ic_excellent"
        case .bad: return "ic_bad"
        case .great: return "ic_great"
        case .poor: return "ic_poor"
        case .neutral: return "ic_neutral"
        case .good: return "ic_good"
        }
    }

    // Relative position of each face, laid out around a center point (in points).
    // Matches the loose hexagon arrangement from the screenshot.
    var offset: CGSize {
        switch self {
        case .awful:     return CGSize(width: -64, height: -125)
        case .excellent: return CGSize(width: 62,  height: -125)
        case .bad:       return CGSize(width: -136, height: -30)
        case .great:     return CGSize(width: 135,  height: -30)
        case .poor:      return CGSize(width: -108, height: 86)
        case .good:      return CGSize(width: 107,  height: 86)
        case .neutral:   return CGSize(width: 0,    height: 138)
        }
    }

    var diameter: CGFloat {
        self == .neutral ? 68 : 72
    }
}

// MARK: - Single mood button (image + label)

private struct MoodButton: View {
    let mood: MoodKind
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(mood.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: mood.diameter, height: mood.diameter)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isSelected ? 0.9 : 0), lineWidth: 3)
                    )
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(mood.label)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color(.label))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full check-in view

struct MoodCheckInView: View {
    /// Called with the chosen mood (and the reason typed on the follow-up
    /// screen) once the user taps Save there.
    var onSelect: ((MoodKind, String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: AppThemeManager
    @State private var selected: MoodKind? = nil

    // Drives the mood-detail / "add reason" screen that opens after a face is tapped.
    @State private var showDetail: Bool = false

    private var pinkRed: Color { themeManager.primaryColor }

    var body: some View {
        VStack {
            Spacer(minLength: 40)

            ZStack {
                ForEach(MoodKind.allCases) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selected == mood,
                        action: { choose(mood) }
                    )
                    .offset(mood.offset)
                }

                titleText
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            Spacer()

            closeButton
                .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .fullScreenCover(isPresented: $showDetail) {
            if let mood = selected {
                MoodDetailView(
                    mood: mood,
                    date: Date(),
                    onSave: { reason in
                        AnalyticsManager.shared.logMoodLogged(moodValue: mood.rawValue)
                        onSelect?(mood, reason)
                        dismiss()
                    },
                    onCancel: {
                        // User backed out of the reason screen; let them pick again.
                        selected = nil
                    }
                )
            }
        }
    }

    private var titleText: some View {
        Text("How you feel now?")
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundColor(Color(.label))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.label))
                .frame(width: 52, height: 52)
                .background(
                    Circle().stroke(Color(.label).opacity(0.5), lineWidth: 1.5)
                )
        }
    }

    private func choose(_ mood: MoodKind) {
        Haptics.selection()
        selected = mood
        // Small delay so the selection highlight is visible before the detail screen opens.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showDetail = true
        }
    }
}

#Preview {
    MoodCheckInView()
        .environmentObject(AppThemeManager())
}
