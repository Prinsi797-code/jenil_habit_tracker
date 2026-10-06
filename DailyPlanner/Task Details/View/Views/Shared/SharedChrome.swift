//
//  SharedChrome.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
 
// MARK: - Header (identical across all screens)
 
struct TaskHeaderView: View {
    let emoji: String
    let name: String
    let isFavorite: Bool
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("taskDetailOpenCount") private var openCount: Int = 0
 
    @EnvironmentObject var viewModel: TaskDetailViewModel
  
    var body: some View {
        HStack {
            Button(action: {
                openCount += 1
                let flag = RemoteConfigManager.shared.interTaskDetailFlag
                if flag > 0 && openCount % flag == 0 {
                    InterstitialAdManager.shared.showAd(adUnitID: RemoteConfigManager.shared.interTaskDetailID)
                }
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Spacer()
            HStack(spacing: 6) {
                Text(emoji)
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color.defaultPrimary)
                        .font(.system(size: 16))
                }
            }
            Spacer()
            Menu {
                Button {
                    viewModel.actionHandler?(.edit)
                } label: {
                    Text("Edit")
                }
                
                Divider()
                
                Button {
                    viewModel.actionHandler?(.archive)
                } label: {
                    Text("Archive")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    viewModel.deleteHabit()
                    dismiss()
                } label: {
                    Text("Delete")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}
 
// MARK: - Small icon + label used in footers (Memo, Stat, Style, Sound...)
 
struct IconLabel: View {
    let systemIcon: String
    let label: String
    var iconColor: Color = .primary
    var bgColor: Color = Color.white.opacity(0.6)
 
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemIcon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .padding(14)
                .background(bgColor)
                .clipShape(Circle())
            Text(label).font(.system(size: 13)).foregroundColor(.secondary)
        }
    }
}
 
// MARK: - Bottom Memo / Stat row (shared by every task type)
 
struct MemoStatRow: View {
    @EnvironmentObject var viewModel: TaskDetailViewModel

    var body: some View {
        HStack(spacing: 90) {
            Button {
                viewModel.showMemoSheet = true
            } label: {
                IconLabel(systemIcon: "note.text", label: "Memo", iconColor: .orange, bgColor: Color.orange.opacity(0.15))
            }
            
            Button {
                viewModel.showStatSheet = true
            } label: {
                IconLabel(systemIcon: "chart.bar.fill", label: "Stat", iconColor: .cyan, bgColor: Color.cyan.opacity(0.15))
            }
        }
    }
}
 
// MARK: - Progress ring used by several body variants
 
struct ProgressRing: View {
    var progress: Double   // 0...1
    var color: Color
    var diameter: CGFloat = 260
    var lineWidth: CGFloat = 14
 
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
    }
}
 
// MARK: - Fillable glass visual (Drink Water style counter)
 
struct GlassView: View {
    var fillRatio: Double
    var color: Color
    
    @State private var animatedFillRatio: Double = 0.0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let phase = now * 2.5 // Adjust this multiplier to change wave speed
                
                ZStack(alignment: .bottom) {
                    // Background tint for the empty part of the glass
                    color.opacity(0.15)
                    
                    // The liquid wave fill
                    Wave(progress: animatedFillRatio, waveHeight: animatedFillRatio > 0 && animatedFillRatio < 1 ? 0.03 * geo.size.height : 0, phase: phase)
                        .fill(
                            LinearGradient(colors: [color.opacity(0.7), color], startPoint: .top, endPoint: .bottom)
                        )
                    
                    // Inner highlight to simulate glass reflections
                    TrapezoidShape()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .clipShape(TrapezoidShape())
            }
            .onAppear {
                animatedFillRatio = fillRatio
            }
            .onChange(of: fillRatio) { newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animatedFillRatio = newValue
                }
            }
        }
    }
}

// Custom animated wave shape
struct Wave: Shape {
    var progress: Double
    var waveHeight: Double
    var phase: Double

    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(progress, AnimatablePair(waveHeight, phase)) }
        set {
            progress = newValue.first
            waveHeight = newValue.second.first
            phase = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let progressHeight = height * (1 - progress)

        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: progressHeight))

        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / 60
            let sine = sin(relativeX + phase)
            let y = progressHeight + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}
 
struct TrapezoidShape: Shape {
    var cornerRadius: CGFloat = 16
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * 0.05
        let bottomInset = rect.width * 0.15
        
        let p1 = CGPoint(x: rect.minX + topInset, y: rect.minY)
        let p2 = CGPoint(x: rect.maxX - topInset, y: rect.minY)
        let p3 = CGPoint(x: rect.maxX - bottomInset, y: rect.maxY)
        let p4 = CGPoint(x: rect.minX + bottomInset, y: rect.maxY)
        
        path.move(to: CGPoint(x: (p1.x + p2.x) / 2, y: p1.y))
        path.addArc(tangent1End: p2, tangent2End: p3, radius: cornerRadius)
        path.addArc(tangent1End: p3, tangent2End: p4, radius: cornerRadius)
        path.addArc(tangent1End: p4, tangent2End: p1, radius: cornerRadius)
        path.addArc(tangent1End: p1, tangent2End: p2, radius: cornerRadius)
        
        path.closeSubpath()
        return path
    }
}
