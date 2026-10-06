import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
    let adUnitID: String
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    var body: some View {
        if isPremium {
            EmptyView()
        } else {
            BannerAdViewController(adUnitID: adUnitID)
        }
    }
}

struct BannerAdViewController: UIViewControllerRepresentable {
    let adUnitID: String
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let viewWidth = UIScreen.main.bounds.width
        let bannerView = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: viewWidth))
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = viewController
        
        viewController.view.addSubview(bannerView)
        
        // Add constraints to position the banner at the bottom or let SwiftUI layout handle it
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        if !adUnitID.isEmpty {
            bannerView.load(Request())
        }
        
        return viewController
        
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}
