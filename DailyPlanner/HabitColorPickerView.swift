//
//  HabitColorPickerView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 31/07/26.
//

import SwiftUI

struct ColorPalette {
    let name: String
    let colors: [String]
}

struct HabitColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColorHex: String
    
    @State private var selectedCategory = "Smoothie & Juice Palette"
    
    private let pageBackground = Color(.systemGroupedBackground)
    private let cardSurface = Color(.systemBackground)
    private let pinkAccent = Color(red: 1.0, green: 0.4, blue: 0.5)
    
    let palettes: [ColorPalette] = [
        ColorPalette(name: "Smoothie & Juice Palette", colors: [
            "#FF85A2", "#F96287", "#FF95AA", "#FFB4C9", "#FFB067", "#FFB575",
            "#FFA155", "#FFB141", "#FFD755", "#FFE957", "#FFCE44", "#FFEA7E",
            "#B3E283", "#94D75E", "#B5E384", "#88D54F", "#C9EC9A", "#77B6F3",
            "#5EA1E6", "#78CAFA", "#509CE2", "#82CFFF", "#AD66FF", "#C986FF",
            "#A854FF", "#BD7AFF", "#A856FF", "#FF4B5A", "#FF3748", "#FF6E6E",
            "#FF5757"
        ]),
        ColorPalette(name: "Macaron Palette", colors: [
            "#F8C8D4", "#F6CDD6", "#EBAEBC", "#FCDFE4", "#FBA8B4", "#D8A6A8",
            "#F7C89F", "#F4BC82", "#F4B084", "#F5AD98", "#DCAD86", "#F6AD8B",
            "#FEE0B2", "#FCF1A1", "#F3E884", "#FCF5B5", "#F7E898", "#FCE663",
            "#FCD568", "#A4EBD4", "#C0E5B6", "#96CBA8", "#BDE4C1", "#A2DEB5",
            "#B8D3B2", "#BDE2FA", "#D3E9FA", "#95CAE9", "#B0D3F8", "#B8D2EF",
            "#AEDBF6", "#DAF1FD", "#D0AEE8", "#BCA3DC", "#D8BEE6", "#D5CEE8",
            "#ADC3F7", "#DBCDF3", "#DEC5E3"
        ]),
        ColorPalette(name: "Dopamine Palette", colors: [
            "#FF4B4B", "#FF1E72", "#DF1A3C", "#FF6D88", "#FF0060", "#FF8E00",
            "#FF6F20", "#FFA300", "#FF8E35", "#FF691D", "#FFD600", "#FFEB3B",
            "#F6FF00", "#FFC200", "#00FF7F", "#4BFF20", "#00E37F", "#2FD466",
            "#00BFFF", "#177DF5", "#4A90E2", "#00CFFF", "#00AEEF", "#A000FF",
            "#D500F9", "#B828FF", "#A439FF", "#8A2BE2", "#FF49B3", "#FF007F",
            "#FF3399", "#D8005A", "#FF356A"
        ]),
        ColorPalette(name: "Morandi Palette", colors: [
            "#B2B2B2", "#C1C5C0", "#989C96", "#8B8F89", "#DFD3C3", "#D5C3B3",
            "#E4DCD0", "#BBA28D", "#D8BDB1", "#CEAEAA", "#E3CFCF", "#BB9187",
            "#D4AC9F", "#A1B2A6", "#8A9F8E", "#B6C5B3", "#7C9081", "#BDCDB9",
            "#8596A4", "#687889", "#97A8B4", "#5A6B7C", "#BFC5CE", "#9BA0A9",
            "#C4C1D6", "#807C8D", "#DFD1A5", "#BBAA7F", "#DFD495", "#A69666"
        ]),
        ColorPalette(name: "Vintage Nostalgia Palette", colors: [
            "#C0392B", "#96281B", "#D35400", "#E67E22", "#A93226", "#CA6F1E",
            "#DC7633", "#A04000", "#BA4A00", "#873600", "#AF601A", "#6E2C00",
            "#512E05", "#D4AC0D", "#D4AC0D", "#B7950B", "#D4AC0D", "#9A7D0A",
            "#4A5E30", "#394A26", "#728958", "#50683C", "#406184", "#567D9F",
            "#314B69", "#7495B4", "#F3E5AB", "#E7DBB5", "#D1C099", "#A79B75",
            "#6B705C", "#A5A58D", "#6B705C", "#4F594D", "#373D35"
        ]),
        ColorPalette(name: "Oriental Palette", colors: [
            "#FF4500", "#E74C3C", "#900C3F", "#FF0000", "#FF69B4", "#C70039",
            "#C70039", "#FF5733", "#D35400", "#B9770E", "#A04000", "#F1C40F",
            "#EFFF33", "#FFA833", "#FFC300", "#D4AC0D", "#B6F300", "#9CCC65"
        ])
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                
                Text("Color")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            ScrollViewReader { proxy in
                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(palettes, id: \.name) { palette in
                            let isSelected = selectedCategory == palette.name
                            Text(palette.name)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(isSelected ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule().fill(isSelected ? AnyShapeStyle(pinkAccent) : AnyShapeStyle(Color(.systemBackground)))
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = palette.name
                                        proxy.scrollTo(palette.name, anchor: .top)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                
                // Color Grids
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(palettes, id: \.name) { palette in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(palette.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .id(palette.name)
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(0..<palette.colors.count, id: \.self) { index in
                                        let hex = palette.colors[index]
                                        let isSelected = selectedColorHex.lowercased() == hex.lowercased()
                                        
                                        Circle()
                                            .fill(Color(hex: hex) ?? .gray)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                                                    .shadow(color: .black.opacity(isSelected ? 0.2 : 0), radius: 3)
                                            )
                                            .scaleEffect(isSelected ? 1.1 : 1.0)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    selectedColorHex = hex
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
