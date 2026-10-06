import SwiftUI

struct UsageTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let tips = [
        ("Quick mark as done", "ic_tip1", "Quickly swipe right to complete habits."),
        ("Enter habit page", "ic_tip2", "Click to enter the habit interface"),
        ("More quick actions", "ic_tip3", "Swipe left to skip, add, hide or reset"),
        ("Quick Filter", "ic_tip4", "Tap on All button to open filter"),
        ("Check in", "ic_tip5", "Select a Task to check task wise activity"),
        ("Track", "ic_tip6", "Track your streaks and stay motivated.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: {
                    InterstitialAdManager.shared.showAdIfAppropriate(
                        flag: RemoteConfigManager.shared.interUsedTipsFlag,
                        adKey: "interUsedTips",
                        adUnitID: RemoteConfigManager.shared.interUsedTipsID
                    )
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Usage Tips")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Placeholder to balance the layout
                Image(systemName: "chevron.left")
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            TabView {
                ForEach(0..<tips.count, id: \.self) { index in
                    VStack(spacing: 60) {
                        Text(tips[index].0)
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                        
                        Image(tips[index].1)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 20)
                        
                        Text(tips[index].2)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = .darkGray
                UIPageControl.appearance().pageIndicatorTintColor = .lightGray
            }
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            InterstitialAdManager.shared.loadAd(adUnitID: RemoteConfigManager.shared.interUsedTipsID)
            InterstitialAdManager.shared.trackScreenAppear(adKey: "interUsedTips")
        }
    }
}
