//
//  MoodDetailView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 29/07/26.
//

import SwiftUI


// MARK: - Drawn face: dot eyes, a smile, and two small "blush" dashes on each cheek

private struct MoodFaceView: View {
    let mood: MoodKind
    let diameter: CGFloat

    var body: some View {
        Image(mood.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
    }
}

// MARK: - Mood detail / note screen

struct MoodDetailView: View {
    let mood: MoodKind
    let date: Date

    /// Called when the user taps Save, with the (possibly empty) note text.
    var onSave: (String) -> Void = { _ in }
    /// Called when the user taps the X to dismiss without saving.
    var onCancel: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var noteText: String = ""
    @State private var isEditingNote: Bool = false
    @FocusState private var noteFieldFocused: Bool

    @EnvironmentObject private var themeManager: AppThemeManager

    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 12)

            card
                .padding(.horizontal, 20)
                .padding(.top, 18)

            Spacer()

            saveButton
                .padding(.bottom, 60)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture {
            noteFieldFocused = false
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(dateString)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(Color(.label))

            HStack {
                Button(action: {
                    noteFieldFocused = false
                    onCancel()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.label))
                        .frame(width: 34, height: 34)
                }
                Spacer()
            }
        }
        .frame(height: 34)
    }

    // MARK: Card

    private var card: some View {
        VStack(spacing: 22) {
            MoodFaceView(mood: mood, diameter: 100)

            moodLabel

            noteField
        }
        .padding(.top, 44)
        .padding(.bottom, 44)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.cardSurface)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
    }

    private var moodLabel: some View {
        ZStack {
            // Hand-drawn marker highlight behind the text
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray4).opacity(0.6))
                .frame(width: CGFloat(mood.label.count) * 15 + 24, height: 16)
                .rotationEffect(.degrees(-1.5))
                .offset(y: 3)

            Text(mood.label)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
        }
    }

    @ViewBuilder
    private var noteField: some View {
        if isEditingNote || !noteText.isEmpty {
            TextEditor(text: $noteText)
                .focused($noteFieldFocused)
                .scrollContentBackground(.hidden)
                .font(.system(size: 16, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(minHeight: 60, maxHeight: 140)
        } else {
            Text("Tap to write a note")
                .font(.system(size: 17, design: .rounded))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.top, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    isEditingNote = true
                    noteFieldFocused = true
                }
        }
    }

    // MARK: Footer

    private var saveButton: some View {
        Button(action: {
            noteFieldFocused = false
            onSave(noteText)
            dismiss()
        }) {
            Text("Save")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 60)
                .padding(.vertical, 16)
                .background(Capsule().fill(pinkGradient))
                .shadow(color: pinkRed.opacity(0.35), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    MoodDetailView(mood: .good, date: Date())
        .environmentObject(AppThemeManager())
}
