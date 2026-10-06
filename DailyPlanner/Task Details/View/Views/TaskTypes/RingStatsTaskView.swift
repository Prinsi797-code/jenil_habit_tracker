//
//  RingStatsTaskView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
 
struct RingStatsBody: View {
    @ObservedObject var viewModel: TaskDetailViewModel
 
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ProgressRing(progress: viewModel.progress, color: viewModel.accentColor)
                VStack(spacing: 6) {
                    Text("🛌")
                    Text(viewModel.current == 0 ? "--" : "\(Int(viewModel.current))")
                        .font(.system(size: 34, weight: .bold))
                    Text("/\(Int(viewModel.goal)) \(viewModel.goalUnitLabel)")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
 
            Button(action: viewModel.logSleep) {
                Text("Log Sleep")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
 
            HStack(spacing: 12) {
                statCard(icon: "moon.stars", label: "Duration")
                statCard(icon: "checkmark.seal", label: "Quality")
            }
            .padding(.horizontal, 24)
 
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(height: 90)
                .overlay(Text("No data").foregroundColor(.secondary))
                .padding(.horizontal, 24)
 
            HStack(spacing: 12) {
                statPill(color: .orange, label: "Awake")
                statPill(color: .cyan, label: "REM")
            }
            .padding(.horizontal, 24)
        }
    }
 
    private func statCard(icon: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(label).font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
            }
            Text("--").font(.system(size: 20, weight: .bold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
 
    private func statPill(color: Color, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(label).font(.system(size: 15, weight: .medium))
                Spacer()
                Text("--%").foregroundColor(.secondary)
            }
            Text("--").font(.system(size: 13)).foregroundColor(color)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
