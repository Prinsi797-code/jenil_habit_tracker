import Foundation
import GoogleMobileAds
import UIKit

class AppOpenAdManager: NSObject, FullScreenContentDelegate {
    static let shared = AppOpenAdManager()
    
    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    private var isShowingAd = false
    private var isPremium: Bool {
        return UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    /// Ad is valid for 4 hours.
    private func wasLoadTimeLessThanNHoursAgo(timeoutInHours: Int) -> Bool {
        guard let loadTime = loadTime else { return false }
        let timeIntervalBetweenNowAndLoadTime = Date().timeIntervalSince(loadTime)
        let secondsPerHour: Double = 3600.0
        let intervalInHours = timeIntervalBetweenNowAndLoadTime / secondsPerHour
        return intervalInHours < Double(timeoutInHours)
    }
    
    private var isAdAvailable: Bool {
        return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInHours: 4)
    }
    
    func loadAd() {
        if isPremium { return }
        if isAdAvailable { return }
        
        let adUnitID = RemoteConfigManager.shared.appOpenID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !adUnitID.isEmpty else { return }
        
        AppOpenAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("App open ad failed to load with error: \(error.localizedDescription)")
                self.appOpenAd = nil
                self.loadTime = nil
                return
            }
            
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
            print("App open ad loaded successfully.")
        }
    }
    
    func showAdIfAvailable() {
        if isPremium { return }
        if isShowingAd { return }
        
        let flag = RemoteConfigManager.shared.appOpenFlag
        let adKey = "app_open"
        
        print("--- App Open Ad Check ---")
        print("Flag: \(flag), isAdAvailable: \(isAdAvailable)")
        
        switch flag {
        case 0:
            print("Skipping app open ad: Flag is 0 (Don't show).")
            return
        case 1:
            let shownKey = "AdShownLifetime_\(adKey)"
            if UserDefaults.standard.bool(forKey: shownKey) {
                print("Skipping app open ad: Flag is 1 (Once in a lifetime) and already shown.")
                return
            }
            UserDefaults.standard.set(true, forKey: shownKey)
        case 2:
            let shownKey = "AdShownDate_\(adKey)"
            if let lastShownDate = UserDefaults.standard.object(forKey: shownKey) as? Date,
               Calendar.current.isDateInToday(lastShownDate) {
                print("Skipping app open ad: Flag is 2 (Once a day) and already shown today.")
                return
            }
            UserDefaults.standard.set(Date(), forKey: shownKey)
        case 3:
            print("Flag 3 (Every time) check passed.")
            break
        default:
            print("Skipping app open ad: Unknown flag value \(flag).")
            return
        }
        
        guard isAdAvailable, let ad = appOpenAd else {
            print("App open ad not ready. Attempting to load.")
            loadAd()
            return
        }
        
        guard let rootViewController = getRootViewController() else { return }
        
        ad.present(from: rootViewController)
    }
    
    // MARK: - FullScreenContentDelegate
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad will be presented.")
        isShowingAd = true
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad dismissed.")
        appOpenAd = nil
        isShowingAd = false
        loadAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("App open ad failed to present with error: \(error.localizedDescription)")
        appOpenAd = nil
        isShowingAd = false
        loadAd()
    }
    
    // MARK: - Helpers
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        return topController
    }
}
