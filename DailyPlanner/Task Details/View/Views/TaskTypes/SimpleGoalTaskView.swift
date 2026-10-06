//
//  SimpleGoalTaskView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
 
struct SimpleGoalBody: View {
    @ObservedObject var viewModel: TaskDetailViewModel
 
    var body: some View {
        ZStack {
            ProgressRing(progress: viewModel.progress, color: viewModel.accentColor)
            VStack(spacing: 8) {
                Text(viewModel.emoji).font(.system(size: 28))
                HStack(spacing: 8) {
                    Text("\(Int(viewModel.current))")
                        .font(.system(size: 44, weight: .bold))
                    Button(action: { viewModel.add(viewModel.task.stepAmount) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .offset(x: 14)
                Text("/\(Int(viewModel.goal)) \(viewModel.goalUnitLabel)")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
 
struct SimpleGoalFooter: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    var addAmount: Double = 500
 
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                Button(action: { viewModel.add(addAmount) }) {
                    Text("Add")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 140)
                        .padding(.vertical, 16)
                        .background(viewModel.accentColor)
                        .clipShape(Capsule())
                }
                Button(action: viewModel.markComplete) {
                    Image(systemName: "checkmark")
                        .foregroundColor(viewModel.accentColor)
                        .frame(width: 52, height: 52)
                        .background(viewModel.accentColor.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            MemoStatRow()
        }
        .frame(maxWidth: .infinity)
    }
}
