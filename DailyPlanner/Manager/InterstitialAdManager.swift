import GoogleMobileAds
import SwiftUI

class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()
    private var interstitials: [String: InterstitialAd] = [:]
    private var screenAppearTimes: [String: Date] = [:]
    
    override init() {
        super.init()
    }
    
    func loadAd(adUnitID: String) {
        guard !adUnitID.isEmpty else { return }
        
        let request = Request()
        InterstitialAd.load(with: adUnitID,
                            request: request,
                            completionHandler: { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            self?.interstitials[adUnitID] = ad
            ad?.fullScreenContentDelegate = self
        })
    }
    
    func showAd(adUnitID: String) {
        if let interstitial = interstitials[adUnitID],
           let root = getRootViewController() {
            interstitial.present(from: root)
        } else {
            print("Ad wasn't ready")
            loadAd(adUnitID: adUnitID) // Try loading again if it wasn't ready
        }
    }
    
    func trackScreenAppear(adKey: String) {
        screenAppearTimes[adKey] = Date()
    }
    
    func showAdIfAppropriate(flag: Int, adKey: String, adUnitID: String) {
        if UserDefaults.standard.bool(forKey: "isPremium") {
            print("Skipping interstitial ad: User is premium.")
            return
        }
        
        print("--- Interstitial Ad Check (\(adKey)) ---")
        print("Flag: \(flag), AdUnitID: \(adUnitID.isEmpty ? "EMPTY" : adUnitID)")
        
        guard !adUnitID.isEmpty else {
            print("Skipping ad: AdUnitID is empty.")
            return
        }
        
        // Don't show ad if user spent less than 10 seconds on screen
        if let appearTime = screenAppearTimes[adKey] {
            let timeSpent = Date().timeIntervalSince(appearTime)
            if timeSpent < 10 {
                print("User spent only \(Int(timeSpent))s on screen, skipping ad (needs 10s).")
                return
            } else {
                print("User spent \(Int(timeSpent))s on screen. Proceeding to flag logic.")
            }
        } else {
            print("No appear time found for \(adKey). Proceeding to flag logic.")
        }
        
        switch flag {
        case 0:
            print("Skipping ad: Flag is 0 (Don't show).")
            return
        case 1:
            let shownKey = "AdShownLifetime_\(adKey)"
            if UserDefaults.standard.bool(forKey: shownKey) {
                print("Skipping ad: Flag is 1 (Once in a lifetime) and already shown.")
                return
            }
            UserDefaults.standard.set(true, forKey: shownKey)
            print("Flag 1 check passed.")
        case 2:
            let shownKey = "AdShownDate_\(adKey)"
            if let lastShownDate = UserDefaults.standard.object(forKey: shownKey) as? Date,
               Calendar.current.isDateInToday(lastShownDate) {
                print("Skipping ad: Flag is 2 (Once a day) and already shown today.")
                return
            }
            UserDefaults.standard.set(Date(), forKey: shownKey)
            print("Flag 2 check passed.")
        case 3:
            print("Flag 3 (Every time) check passed.")
            break
        default:
            print("Skipping ad: Unknown flag value \(flag).")
            return
        }
        
        print("Attempting to show ad...")
        showAd(adUnitID: adUnitID)
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed")
        if let interstitial = ad as? InterstitialAd {
            loadAd(adUnitID: interstitial.adUnitID) // Load the next ad
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        if let interstitial = ad as? InterstitialAd {
            loadAd(adUnitID: interstitial.adUnitID)
        }
    }
    
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
