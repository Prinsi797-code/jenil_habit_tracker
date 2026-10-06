//
//  LimitTaskView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
 
struct LimitBody: View {
    @ObservedObject var viewModel: TaskDetailViewModel
 
    var body: some View {
        ZStack {
            ProgressRing(progress: viewModel.progress,
                         color: viewModel.isOverLimit ? .red : viewModel.accentColor)
            VStack(spacing: 8) {
                Text(viewModel.emoji).font(.system(size: 28))
                Text("\(Int(viewModel.current))")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(viewModel.isOverLimit ? .red : .primary)
                Text("limit \(Int(viewModel.goal)) \(viewModel.goalUnitLabel)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                if viewModel.isOverLimit {
                    Text("Over your limit")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
    }
}
 
struct LimitFooter: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    var addAmount: Double = 1
 
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                Button(action: { viewModel.add(addAmount) }) {
                    Text("Add")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isOverLimit ? Color.red : viewModel.accentColor)
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
    }
}
