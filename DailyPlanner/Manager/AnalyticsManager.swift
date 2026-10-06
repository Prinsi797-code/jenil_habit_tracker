import Foundation
import FirebaseAnalytics

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Habit Events
    
    func logHabitCreated(habitType: String, hasReminder: Bool, hasEndDate: Bool) {
        Analytics.logEvent("habit_created", parameters: [
            "habit_type": habitType,
            "has_reminder": hasReminder ? "true" : "false",
            "has_end_date": hasEndDate ? "true" : "false"
        ])
    }
    
    func logHabitEdited() {
        Analytics.logEvent("habit_edited", parameters: nil)
    }
    
    func logHabitDeleted() {
        Analytics.logEvent("habit_deleted", parameters: nil)
    }
    
    func logHabitCompleted() {
        Analytics.logEvent("habit_completed", parameters: nil)
    }
    
    func logHabitIdeaUsed() {
        Analytics.logEvent("habit_idea_used", parameters: nil)
    }
    
    // MARK: - Mood Events
    
    func logMoodLogged(moodValue: String) {
        Analytics.logEvent("mood_logged", parameters: [
            "mood_value": moodValue
        ])
    }
    
    // MARK: - Monetization & Premium Events
    
    func logPremiumPaywallViewed(source: String = "unknown") {
        Analytics.logEvent("premium_paywall_viewed", parameters: [
            "source_screen": source
        ])
    }
    
    func logPremiumPurchaseStarted() {
        Analytics.logEvent("premium_purchase_started", parameters: nil)
    }
    
    func logPremiumPurchaseSuccess() {
        Analytics.logEvent("premium_purchase_success", parameters: nil)
    }
    
    func logPremiumPurchaseFailed(error: String) {
        Analytics.logEvent("premium_purchase_failed", parameters: [
            "error_reason": error
        ])
    }
    
    func logPremiumPurchaseCancelled() {
        Analytics.logEvent("premium_purchase_cancelled", parameters: nil)
    }
    
    func logPremiumRestoreSuccess() {
        Analytics.logEvent("premium_restore_success", parameters: nil)
    }
    
    func logPremiumRestoreFailed() {
        Analytics.logEvent("premium_restore_failed", parameters: nil)
    }
    
    func logPaywallDismissed() {
        Analytics.logEvent("premium_paywall_dismissed", parameters: nil)
    }
    
    // MARK: - Settings & App Events
    
    func logOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }
    
    func logThemeChanged() {
        Analytics.logEvent("theme_changed", parameters: nil)
    }
    
    func logWidgetThemeChanged() {
        Analytics.logEvent("widget_theme_changed", parameters: nil)
    }
    
    func logLanguageChanged() {
        Analytics.logEvent("language_changed", parameters: nil)
    }
    
    func logDataExported() {
        Analytics.logEvent("data_exported", parameters: nil)
    }
    
    func logNotificationSettingsUpdated() {
        Analytics.logEvent("notification_settings_updated", parameters: nil)
    }
    
    func logQuoteShared() {
        Analytics.logEvent("quote_shared", parameters: nil)
    }
}
