//
//  CounterTaskView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
 
struct CounterBody: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    let unit: String
 
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(viewModel.current))")
                    .font(.system(size: 64, weight: .bold))
                Text(unit)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text("/\(Int(viewModel.goal)) \(unit)")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
 
            Button(action: viewModel.reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.accentColor)
            }
            .padding(.top, 4)
 
            GlassView(fillRatio: viewModel.progress, color: viewModel.accentColor)
                .frame(width: 200, height: 320)
                .padding(.top, 35)
        }
    }
}
 
struct CounterFooter: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    var addAmount: Double = 250
 
    var body: some View {
        VStack(spacing: 24) {
            Button(action: { viewModel.add(addAmount) }) {
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(viewModel.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Text("Add")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            MemoStatRow()
        }
    }
}
