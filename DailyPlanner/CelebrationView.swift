import SwiftUI
#if canImport(Lottie)
import Lottie
#endif

struct CelebrationView: View {
    @Binding var isPresented: Bool
    @AppStorage("neverShowCelebration") private var neverShowCelebration = false
    
    var body: some View {
        ZStack {
            // Background
            Color.white.opacity(0.9)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Texts
                VStack(spacing: 16) {
                    Text("WELL DONE!!")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.68)) // Teal
                    
                    Text("YOU DID IT!!")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.96, green: 0.44, blue: 0.16)) // Orange
                }
                .multilineTextAlignment(.center)
                .shadow(color: .white.opacity(0.8), radius: 5, x: 0, y: 0)
                
                Spacer()
                
                // Don't show again button
                Button(action: {
                    neverShowCelebration = true
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Don't show again")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 50)
            }
            
            // Lottie Animation Overlay
            LottieView(animation: .named("celebration-ribbon"))
                .configure { lottieView in
                    lottieView.contentMode = .scaleAspectFill
                }
                .playing(loopMode: .playOnce)
                .resizable()
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .onTapGesture {
            withAnimation {
                isPresented = false
            }
        }
    }
}
