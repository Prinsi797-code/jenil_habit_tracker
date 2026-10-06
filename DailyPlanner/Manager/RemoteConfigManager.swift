import FirebaseRemoteConfig
import Foundation

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    private var remoteConfig: RemoteConfig
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        // During development, reduce fetch interval to 0 so config updates immediately.
        settings.minimumFetchInterval = 0 
        remoteConfig.configSettings = settings
    }
    
    func fetchRemoteConfig(completion: @escaping (Bool) -> Void) {
        remoteConfig.fetch { [weak self] (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                self?.remoteConfig.activate { changed, error in
                    completion(true)
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
                completion(false)
            }
        }
    }
    
    // MARK: - App Open
    
    var appOpenFlag: Int {
        return remoteConfig.configValue(forKey: "app_open_flag").numberValue.intValue
    }
    
    var appOpenID: String {
        return remoteConfig.configValue(forKey: "app_open_id").stringValue
    }
    
    // MARK: - Banner Main
    
    var bannerMainFlag: Int {
        return remoteConfig.configValue(forKey: "banner_main_flag").numberValue.intValue
    }
    
    var bannerMainID: String {
        return remoteConfig.configValue(forKey: "banner_main_id").stringValue
    }
    
    // MARK: - Banner Habit
    
    var bannerHabitFlag: Int {
        return remoteConfig.configValue(forKey: "banner_habit_flag").numberValue.intValue
    }
    
    var bannerHabitID: String {
        return remoteConfig.configValue(forKey: "banner_habit_id").stringValue
    }

    // MARK: - Banner Overall
    
    var bannerOverallFlag: Int {
        return remoteConfig.configValue(forKey: "banner_overall_flag").numberValue.intValue
    }
    
    var bannerOverallID: String {
        return remoteConfig.configValue(forKey: "banner_overall_id").stringValue
    }

    // MARK: - Banner Setting
    
    var bannerSettingFlag: Int {
        return remoteConfig.configValue(forKey: "banner_setting_flag").numberValue.intValue
    }
    
    var bannerSettingID: String {
        return remoteConfig.configValue(forKey: "banner_setting_id").stringValue
    }
    
    // MARK: - Interstitial Task Detail
    
    var interTaskDetailFlag: Int {
        return remoteConfig.configValue(forKey: "inter_taskdetail_flag").numberValue.intValue
    }

    var interTaskDetailID: String {
        return remoteConfig.configValue(forKey: "inter_taskdetail_id").stringValue
    }
    
    // MARK: - Interstitial Habit Detail
    
    var interHabitDetailFlag: Int {
        return remoteConfig.configValue(forKey: "inter_habitdetail_flag").numberValue.intValue
    }

    var interHabitDetailID: String {
        return remoteConfig.configValue(forKey: "inter_habitdetail_id").stringValue
    }

    // MARK: - Interstitial Change Language
    
    var interChangeLanguageFlag: Int {
        return remoteConfig.configValue(forKey: "inter_changelanguage_flag").numberValue.intValue
    }

    var interChangeLanguageID: String {
        return remoteConfig.configValue(forKey: "inter_changelanguage_id").stringValue
    }

    // MARK: - Interstitial Language
    
    var interLanguageFlag: Int {
        return remoteConfig.configValue(forKey: "inter_language_flag").numberValue.intValue
    }

    var interLanguageID: String {
        return remoteConfig.configValue(forKey: "inter_language_id").stringValue
    }

    // MARK: - Interstitial Export
    
    var interExportFlag: Int {
        return remoteConfig.configValue(forKey: "inter_export_flag").numberValue.intValue
    }

    var interExportID: String {
        return remoteConfig.configValue(forKey: "inter_export_id").stringValue
    }

    // MARK: - Interstitial Habit Manager
    
    var interHabitManagerFlag: Int {
        return remoteConfig.configValue(forKey: "inter_habitManager_flag").numberValue.intValue
    }

    var interHabitManagerID: String {
        return remoteConfig.configValue(forKey: "inter_habitManager_id").stringValue
    }

    // MARK: - Interstitial More Setting
    
    var interMoreSettingFlag: Int {
        return remoteConfig.configValue(forKey: "inter_moresetting_flag").numberValue.intValue
    }

    var interMoreSettingID: String {
        return remoteConfig.configValue(forKey: "inter_moresetting_id").stringValue
    }

    // MARK: - Interstitial Notification
    
    var interNotificationFlag: Int {
        return remoteConfig.configValue(forKey: "inter_notification_flag").numberValue.intValue
    }

    var interNotificationID: String {
        return remoteConfig.configValue(forKey: "inter_notification_id").stringValue
    }

    // MARK: - Interstitial Theme
    
    var interThemeFlag: Int {
        return remoteConfig.configValue(forKey: "inter_theme_flag").numberValue.intValue
    }

    var interThemeID: String {
        return remoteConfig.configValue(forKey: "inter_theme_id").stringValue
    }

    // MARK: - Interstitial New Habit
    
    var interNewHabitFlag: Int {
        return remoteConfig.configValue(forKey: "inter_newhabit_flag").numberValue.intValue
    }

    var interNewHabitID: String {
        return remoteConfig.configValue(forKey: "inter_newhabit_id").stringValue
    }

    // MARK: - Interstitial Used Tips
    
    var interUsedTipsFlag: Int {
        return remoteConfig.configValue(forKey: "inter_usedtips_flag").numberValue.intValue
    }

    var interUsedTipsID: String {
        return remoteConfig.configValue(forKey: "inter_usedtips_id").stringValue
    }
    
    // MARK: - Interstitial Moods
    var interMoodsFlag: Int {
        return remoteConfig.configValue(forKey: "inter_moods_flag").numberValue.intValue
    }

    var interMoodsID: String {
        return remoteConfig.configValue(forKey: "inter_moods_id").stringValue
    }
    
    //MARK: - native Mood Record
    var nativeMoodRecordFlag: Int {
        return remoteConfig.configValue(forKey: "native_moodrecord_flag").numberValue.intValue
    }
    
    var nativeMoodRecordID: String {
        return remoteConfig.configValue(forKey: "native_moodrecord_id").stringValue
    }
    
    //MARK: - native Done Today
    var nativeDoneTodayFlag: Int {
        return remoteConfig.configValue(forKey: "native_donetoday_flag").numberValue.intValue
    }
    
    var nativeDoneTodayID: String {
        return remoteConfig.configValue(forKey: "native_donetoday_id").stringValue
    }
    

}
