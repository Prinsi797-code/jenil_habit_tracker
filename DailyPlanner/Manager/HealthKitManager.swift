//
//  HealthKitManager.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 31/07/26.
//

import Foundation
import HealthKit

/// Singleton that handles all Apple HealthKit read/write operations.
/// Units that don't map to HealthKit (pages, chapters, sets, reps, etc.) are silently skipped.
enum HealthKitManager {

    // MARK: - Shared Store

    private static let store = HKHealthStore()

    /// Whether the current device supports HealthKit at all.
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// User's preference for HealthKit sync
    static var syncEnabled: Bool {
        if UserDefaults.standard.object(forKey: "appleHealthSync") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "appleHealthSync")
    }

    // MARK: - Unit → HealthKit Type Mapping

    /// Returns the `HKSampleType` that corresponds to a habit's unit string
    /// (and its title, used for disambiguation when multiple HealthKit types share
    /// the same unit — e.g. Protein / Carbs / Fat all use "g").
    ///
    /// Returns `nil` for units that have no HealthKit equivalent.
    static func sampleType(forUnit unit: String, title: String) -> HKSampleType? {
        let lowerUnit  = unit.lowercased().trimmingCharacters(in: .whitespaces)
        let lowerTitle = title.lowercased()

        switch lowerUnit {

        // --- Activity ---
        case "steps":
            return HKQuantityType(.stepCount)
        case "active energy":
            return HKQuantityType(.activeEnergyBurned)
        case "basal energy":
            return HKQuantityType(.basalEnergyBurned)
        case "floors":
            return HKQuantityType(.flightsClimbed)
        case "cycling distance":
            return HKQuantityType(.distanceCycling)
        case "swimming distance":
            return HKQuantityType(.distanceSwimming)
        case "walking + running distance":
            return HKQuantityType(.distanceWalkingRunning)

        // --- Nutrition ---
        case "kcal":
            if lowerTitle.contains("basal") {
                return HKQuantityType(.basalEnergyBurned)
            }
            return HKQuantityType(.activeEnergyBurned)
        case "ml":
            return HKQuantityType(.dietaryWater)
        case "l":
            return HKQuantityType(.dietaryWater)
        case "g":
            if lowerTitle.contains("protein") {
                return HKQuantityType(.dietaryProtein)
            } else if lowerTitle.contains("carb") {
                return HKQuantityType(.dietaryCarbohydrates)
            } else if lowerTitle.contains("fat") {
                return HKQuantityType(.dietaryFatTotal)
            }
            return nil // unknown "g" — skip

        // --- Distance ---
        case "km":
            return HKQuantityType(.distanceWalkingRunning)

        // --- Time-based ---
        case "min":
            if lowerTitle.contains("mindful") || lowerTitle.contains("meditat") {
                return HKCategoryType(.mindfulSession)
            }
            // Exercise / Workout minutes
            return HKQuantityType(.appleExerciseTime)
        case "sleep":
            return HKCategoryType(.sleepAnalysis)

        // --- Stand ---
        case "hr":
            if lowerTitle.contains("stand") {
                return HKQuantityType(.appleStandTime)
            }
            return nil

        default:
            return nil // pages, chapters, sessions, sets, reps, count, kg — no HK mapping
        }
    }

    // MARK: - Permission Request

    /// Requests read & write authorization for the HealthKit type that matches the
    /// given unit/title pair.  Does nothing if the unit has no HealthKit mapping or
    /// if HealthKit is unavailable on this device.
    static func requestPermission(forUnit unit: String, title: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard isAvailable, syncEnabled,
              let type = sampleType(forUnit: unit, title: title) else {
            completion(false)
            return
        }

        var shareTypes: Set<HKSampleType>? = [type]
        
        // Some HealthKit types are read-only for third-party apps.
        // Requesting "toShare" (write access) for them will crash the app.
        if type.identifier == HKQuantityTypeIdentifier.appleExerciseTime.rawValue ||
           type.identifier == HKQuantityTypeIdentifier.appleStandTime.rawValue {
            shareTypes = nil
        }

        store.requestAuthorization(toShare: shareTypes, read: [type]) { success, error in
            if let error = error {
                print("[HealthKit] Authorization error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    // MARK: - Save Data

    static func saveData(value: Double, unit: String, title: String, date: Date = Date()) {
        guard isAvailable, syncEnabled, value > 0,
              let type = sampleType(forUnit: unit, title: title) else { return }

        let start = date

        // Category types (mindful session, sleep) need special handling
        if let categoryType = type as? HKCategoryType {
            saveCategorySample(categoryType: categoryType, value: value, unit: unit, start: start)
            return
        }

        guard let quantityType = type as? HKQuantityType else { return }

        let hkUnit = healthKitUnit(forUnit: unit, title: title)
        guard let hkUnit = hkUnit else { return }

        let quantity = HKQuantity(unit: hkUnit, doubleValue: value)
        let sample   = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: start)

        store.save(sample) { success, error in
            if let error = error {
                print("[HealthKit] Save error: \(error.localizedDescription)")
            } else if success {
                print("[HealthKit] Saved \(value) \(unit) for \"\(title)\"")
            }
        }
    }

    // MARK: - Private Helpers

    /// Maps the app's unit string to an `HKUnit`.
    private static func healthKitUnit(forUnit unit: String, title: String) -> HKUnit? {
        let lowerUnit  = unit.lowercased().trimmingCharacters(in: .whitespaces)
        let lowerTitle = title.lowercased()

        switch lowerUnit {
        case "steps", "floors":
            return .count()
        case "active energy", "basal energy", "kcal":
            return .kilocalorie()
        case "ml":
            return .literUnit(with: .milli)
        case "l":
            return .liter()
        case "g":
            return .gram()
        case "km":
            return .meterUnit(with: .kilo)
        case "cycling distance", "swimming distance", "walking + running distance":
            return .meter()
        case "min":
            if lowerTitle.contains("mindful") || lowerTitle.contains("meditat") {
                return nil // category type, no unit needed
            }
            return .minute()
        case "hr":
            return .minute() // appleStandTime uses minutes
        default:
            return nil
        }
    }

    /// Saves a category sample (mindful session or sleep) as a time interval.
    private static func saveCategorySample(categoryType: HKCategoryType, value: Double, unit: String, start: Date) {
        let durationSeconds = value * 60 // value is in minutes
        
        let categoryValue: Int
        if categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            categoryValue = HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        } else {
            categoryValue = 0 // mindful session
        }

        let sample = HKCategorySample(
            type: categoryType,
            value: categoryValue,
            start: start.addingTimeInterval(-durationSeconds), // session started `value` minutes ago
            end: start
        )

        store.save(sample) { success, error in
            if let error = error {
                print("[HealthKit] Category save error: \(error.localizedDescription)")
            } else if success {
                print("[HealthKit] Saved \(value) min category for \"\(categoryType.identifier)\"")
            }
        }
    }
}
