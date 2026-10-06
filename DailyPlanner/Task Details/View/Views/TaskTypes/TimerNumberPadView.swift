//
//  TimerNumberPadView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 21/09/26.
//

import SwiftUI

struct TimerNumberPadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let accentColor: Color
    var onConfirm: (Double) -> Void

    @State private var inputText: String = "0"
    @State private var selectedUnit: String = "min"

    private let units = ["sec", "min", "hr"]

    private var valueInMinutes: Double {
        let raw = Double(inputText) ?? 0
        switch selectedUnit {
        case "sec": return raw / 60.0
        case "hr":  return raw * 60.0
        default:    return raw
        }
    }

    private var keyBg: Color {
        colorScheme == .dark
            ? Color(.systemGray5)
            : Color(.systemGray6)
    }

    private var sheetBg: Color {
        colorScheme == .dark
            ? Color(.secondarySystemBackground)
            : Color.white
    }

    var body: some View {
        VStack(spacing: 20) {
            // ── Drag Handle ──
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            // ── Value Display ──
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(inputText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: inputText)
                Text(selectedUnit)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)

            // ── Unit Selector ──
            HStack(spacing: 6) {
                ForEach(units, id: \.self) { unit in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedUnit = unit
                        }
                    } label: {
                        Text(unit)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedUnit == unit ? .white : .primary.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(selectedUnit == unit ? accentColor : keyBg)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)

            // ── Number Pad Grid ──
            let spacing: CGFloat = 10
            VStack(spacing: spacing) {
                // Row 1:  1  2  3  AC
                HStack(spacing: spacing) {
                    digitKey("1")
                    digitKey("2")
                    digitKey("3")
                    actionKey(label: "AC") { inputText = "0" }
                }

                // Row 2:  4  5  6  ⌫
                HStack(spacing: spacing) {
                    digitKey("4")
                    digitKey("5")
                    digitKey("6")
                    actionKey(icon: "delete.backward") { deleteLastChar() }
                }

                // Row 3:  7  8  9  |  ✓ (tall)
                // Row 4:  ⌘  0  .  |
                HStack(alignment: .top, spacing: spacing) {
                    // Left 3 columns
                    VStack(spacing: spacing) {
                        HStack(spacing: spacing) {
                            digitKey("7")
                            digitKey("8")
                            digitKey("9")
                        }
                        HStack(spacing: spacing) {
                            // ⌘ key (placeholder, no action)
                            Text("⌘")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.4))
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(keyBg.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            digitKey("0")

                            // Dot key
                            Button { appendDot() } label: {
                                Text(".")
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .background(keyBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(NumPadButtonStyle())
                        }
                    }

                    // Right column — tall confirm button spanning 2 rows
                    Button {
                        onConfirm(valueInMinutes)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity, minHeight: 56 * 2 + spacing)
                            .background(keyBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(NumPadButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(sheetBg.ignoresSafeArea())
    }

    // MARK: - Key Builders

    private func digitKey(_ d: String) -> some View {
        Button { appendDigit(d) } label: {
            Text(d)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(keyBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(NumPadButtonStyle())
    }

    private func actionKey(label: String? = nil, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let label = label {
                    Text(label)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(keyBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(NumPadButtonStyle())
    }

    // MARK: - Input Logic

    private func appendDigit(_ d: String) {
        if inputText == "0" {
            inputText = d
        } else if inputText.count < 6 {
            inputText += d
        }
    }

    private func appendDot() {
        guard !inputText.contains(".") else { return }
        inputText += "."
    }

    private func deleteLastChar() {
        if inputText.count > 1 {
            inputText.removeLast()
        } else {
            inputText = "0"
        }
    }
}

// MARK: - Custom Button Style (press animation)

private struct NumPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
