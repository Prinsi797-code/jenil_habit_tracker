//
//  AppLockManager.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
import LocalAuthentication

@MainActor
final class AppLockManager: ObservableObject {
    @AppStorage("safetyLockEnabled") var isEnabled: Bool = false

    /// True while content should be hidden behind the privacy cover.
    @Published var isLocked: Bool = false

    init() {
        isLocked = isEnabled
    }

    func lockIfNeeded() {
        guard isEnabled else { return }
        isLocked = true
    }

    /// Triggers the system's own Face ID / Touch ID / passcode UI directly.
    func authenticate() {
        guard isEnabled else {
            isLocked = false
            return
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics/passcode set up on the device — fail open rather than
            // permanently locking someone out of a personal habit tracker.
            isLocked = false
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock Daily Planner"
        ) { [weak self] success, _ in
            Task { @MainActor in
                self?.isLocked = !success
            }
        }
    }
}
