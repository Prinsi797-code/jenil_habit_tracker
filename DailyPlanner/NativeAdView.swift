//
//  NativeAdView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 10/08/26.
//

import SwiftUI
import GoogleMobileAds
import Combine

// MARK: - Native Ad Loader

class NativeAdLoader: NSObject, ObservableObject, NativeAdLoaderDelegate, NativeAdDelegate {
    @Published var nativeAd: NativeAd?
    @Published var isLoading = false
    
    private var adLoader: AdLoader?
    
    func loadAd(adUnitID: String) {
        print("--- Native Ad (Mood Records) ---")
        guard !adUnitID.isEmpty else {
            print("Native ad skipped: AdUnitID is empty.")
            return
        }
        guard !isLoading else {
            print("Native ad skipped: Already loading.")
            return
        }
        
        let rootVC = getRootViewController()
        print("Native ad loading with AdUnitID: \(adUnitID)")
        print("RootViewController: \(rootVC != nil ? "Found" : "nil")")
        isLoading = true
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
    
    // MARK: - NativeAdLoaderDelegate
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
        isLoading = false
        print("Native ad loaded successfully.")
        print("Headline: \(nativeAd.headline ?? "nil")")
        print("Body: \(nativeAd.body ?? "nil")")
        print("CTA: \(nativeAd.callToAction ?? "nil")")
        print("Star Rating: \(nativeAd.starRating?.doubleValue ?? 0)")
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("Native ad failed to load: \(error.localizedDescription)")
        isLoading = false
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

// MARK: - Native Ad Card (SwiftUI)

struct NativeAdCardView: View {
    let nativeAd: NativeAd
    
    var body: some View {
        NativeAdRepresentable(nativeAd: nativeAd)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

// MARK: - UIViewRepresentable for GADNativeAdView

struct NativeAdRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = UIColor(white: 0.13, alpha: 1.0)
        nativeAdView.layer.cornerRadius = 20
        nativeAdView.layer.masksToBounds = true
        
        // --- Icon ---
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = 10
        iconView.layer.masksToBounds = true
        iconView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.iconView = iconView
        
        // --- Ad Badge ---
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.25, alpha: 1.0)
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 5
        adBadge.layer.masksToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Headline ---
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.headlineView = headlineLabel
        
        // --- Info icon (AdChoices placeholder) ---
        let infoIcon = UIImageView()
        infoIcon.image = UIImage(systemName: "info.circle")
        infoIcon.tintColor = UIColor(white: 0.5, alpha: 1.0)
        infoIcon.contentMode = .scaleAspectFit
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Star Rating ---
        let starContainer = UIView()
        starContainer.translatesAutoresizingMaskIntoConstraints = false
        starContainer.tag = 1001
        
        // Create 5 star image views
        var previousStar: UIImageView? = nil
        for i in 0..<5 {
            let starView = UIImageView()
            starView.contentMode = .scaleAspectFit
            starView.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            starView.translatesAutoresizingMaskIntoConstraints = false
            starView.tag = 2000 + i
            starContainer.addSubview(starView)
            
            NSLayoutConstraint.activate([
                starView.topAnchor.constraint(equalTo: starContainer.topAnchor),
                starView.bottomAnchor.constraint(equalTo: starContainer.bottomAnchor),
                starView.widthAnchor.constraint(equalToConstant: 14),
                starView.heightAnchor.constraint(equalToConstant: 14),
            ])
            
            if let prev = previousStar {
                starView.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: 2).isActive = true
            } else {
                starView.leadingAnchor.constraint(equalTo: starContainer.leadingAnchor).isActive = true
            }
            previousStar = starView
        }
        if let lastStar = previousStar {
            lastStar.trailingAnchor.constraint(equalTo: starContainer.trailingAnchor).isActive = true
        }
        
        // --- Body ---
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.italicSystemFont(ofSize: 13)
        bodyLabel.textColor = UIColor(white: 0.65, alpha: 1.0)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.bodyView = bodyLabel
        
        // --- CTA Button ---
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.backgroundColor = UIColor(red: 0.30, green: 0.50, blue: 1.0, alpha: 1.0)
        ctaButton.layer.cornerRadius = 22
        ctaButton.layer.masksToBounds = true
        ctaButton.isUserInteractionEnabled = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.callToActionView = ctaButton
        
        // --- Add subviews ---
        nativeAdView.addSubview(iconView)
        nativeAdView.addSubview(adBadge)
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.addSubview(infoIcon)
        nativeAdView.addSubview(starContainer)
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.addSubview(ctaButton)
        
        NSLayoutConstraint.activate([
            // Icon - top left
            iconView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 14),
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            
            // Ad badge - right of icon, vertically centered with icon
            adBadge.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: -8),
            adBadge.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            adBadge.widthAnchor.constraint(equalToConstant: 26),
            adBadge.heightAnchor.constraint(equalToConstant: 18),
            
            // Headline - right of ad badge
            headlineLabel.centerYAnchor.constraint(equalTo: adBadge.centerYAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: adBadge.trailingAnchor, constant: 6),
            headlineLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoIcon.leadingAnchor, constant: -8),
            
            // Info icon - top right
            infoIcon.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 10),
            infoIcon.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            infoIcon.widthAnchor.constraint(equalToConstant: 16),
            infoIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Star rating - below headline, aligned with headline
            starContainer.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            starContainer.leadingAnchor.constraint(equalTo: adBadge.leadingAnchor),
            
            // Body - below icon/star area
            bodyLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 14),
            bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -14),
            
            // CTA Button - full width at bottom
            ctaButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 14),
            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -14),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -14),
            ctaButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        return nativeAdView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        nativeAdView.nativeAd = nativeAd
        
        // Update headline
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // Update body
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        // Update icon
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        // Update CTA
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        // Update star rating
        if let starContainer = nativeAdView.viewWithTag(1001) {
            let rating = nativeAd.starRating?.doubleValue ?? 0
            for i in 0..<5 {
                if let starView = starContainer.viewWithTag(2000 + i) as? UIImageView {
                    let starIndex = Double(i)
                    if starIndex + 1 <= rating {
                        starView.image = UIImage(systemName: "star.fill")
                    } else if starIndex + 0.5 <= rating {
                        starView.image = UIImage(systemName: "star.leadinghalf.filled")
                    } else {
                        starView.image = UIImage(systemName: "star")
                    }
                }
            }
            // Hide star container if no rating
            starContainer.isHidden = (nativeAd.starRating == nil)
        }
    }
}

// MARK: - Convenience wrapper with loading

struct NativeAdContainerView: View {
    let adUnitID: String
    @StateObject private var adLoader = NativeAdLoader()
    
    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let nativeAd = adLoader.nativeAd {
                NativeAdCardView(nativeAd: nativeAd)
            }
        }
        .onAppear {
            print("--- NativeAdContainerView onAppear ---")
            print("isPremium: \(isPremium)")
            print("adUnitID: \(adUnitID)")
            if !isPremium {
                adLoader.loadAd(adUnitID: adUnitID)
            } else {
                print("Native ad skipped: User is premium.")
            }
        }
    }
}
