//
//  AppLockView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI

struct AppLockView: View {
    @ObservedObject var lockManager: AppLockManager

    var body: some View {
        Color.pageSurface
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { lockManager.authenticate() }
            .onAppear { lockManager.authenticate() }
    }
}
