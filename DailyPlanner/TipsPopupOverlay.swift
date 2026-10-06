import SwiftUI

struct TipsPopupOverlay: View {
    @Binding var isPresented: Bool
    
    let tips = [
        ("Quick mark as done", "ic_tip1", "Quickly swipe right to complete habits."),
        ("More options", "ic_tip2", "Swipe left for more options."),
        ("Daily Check-in", "ic_tip3", "Check your daily progress easily."),
        ("Customize", "ic_tip4", "Customize your app theme."),
        ("Widgets", "ic_tip5", "Add widgets to your home screen."),
        ("Track", "ic_tip6", "Track your streaks and stay motivated.")
    ]
    
    var body: some View {
        ZStack {
            // Dark transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // Popup content
            VStack(spacing: 0) {
                TabView {
                    ForEach(0..<tips.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Text(tips[index].0)
                                .font(.system(size: 22, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding(.top, 30)
                            
                            Image(tips[index].1)
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal, 20)
                            
                            Text(tips[index].2)
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                            
                            Spacer()
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = .systemPink
                    UIPageControl.appearance().pageIndicatorTintColor = .lightGray
                }
            }
            .frame(height: 400)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(.horizontal, 15)
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
        }
        .zIndex(100)
    }
}
