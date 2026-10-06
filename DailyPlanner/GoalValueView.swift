//
//  GoalValueView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 31/07/26.
//

import SwiftUI

struct GoalValueView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var goalAmount: String
    @Binding var goalUnit: String
    
    @State private var showUnitSelection = false
    @State private var showNumpad = false
    
    private let pageBackground = Color(.systemGroupedBackground)
    private let cardSurface = Color(.systemBackground)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        Text("Goal Value")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Card
                    VStack(spacing: 0) {
                        // Goal Row
                        Button(action: {
                            withAnimation(.spring()) {
                                showNumpad = true
                            }
                        }) {
                            HStack {
                                Text("Goal")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(goalAmount)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 16)
                        }
                        
                        Divider()
                        
                        // Unit Row
                        NavigationLink(destination: UnitSelectionView(selectedUnit: $goalUnit)) {
                            HStack {
                                Text("Unit")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(goalUnit)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding(.vertical, 16)
                        }
                        
                        Divider()
                        
                        // Health Link Row
                        HStack {
                            Text("Health Link")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Steps")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 20)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(cardSurface))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .background(pageBackground.ignoresSafeArea())
                
                // Dim overlay for numpad
                if showNumpad {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showNumpad = false
                            }
                        }
                }
                
                // Custom Numpad
                CustomNumpad(text: $goalAmount, onDone: {
                    withAnimation(.spring()) {
                        showNumpad = false
                    }
                })
                .offset(y: showNumpad ? 0 : 400)
                .opacity(showNumpad ? 1 : 0)
            }
            .navigationBarHidden(true)
        }
    }
}

struct CustomNumpad: View {
    @Binding var text: String
    var onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 10)
            
            HStack(spacing: 10) {
                // Column 1
                VStack(spacing: 10) {
                    numpadButton("1")
                    numpadButton("4")
                    numpadButton("7")
                    numpadButton(icon: "command", isSpecial: true) {}
                }
                // Column 2
                VStack(spacing: 10) {
                    numpadButton("2")
                    numpadButton("5")
                    numpadButton("8")
                    numpadButton("0")
                }
                // Column 3
                VStack(spacing: 10) {
                    numpadButton("3")
                    numpadButton("6")
                    numpadButton("9")
                    numpadButton(".")
                }
                // Column 4
                VStack(spacing: 10) {
                    numpadButton("AC", isSpecial: true) { text = "" }
                    numpadButton(icon: "delete.left", isSpecial: true) {
                        if !text.isEmpty { text.removeLast() }
                    }
                    Button(action: onDone) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
        )
    }
    
    @ViewBuilder
    private func numpadButton(_ title: String? = nil, icon: String? = nil, isSpecial: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            if let action = action {
                action()
            } else if let title = title, !isSpecial {
                text += title
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                
                if let title = title {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSpecial ? .primary : .primary)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55)
        }
    }
}
