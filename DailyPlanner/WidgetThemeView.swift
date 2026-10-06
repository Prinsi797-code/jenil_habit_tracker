//
//  WidgetThemeView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 28/07/26.
//

import SwiftUI
import AVKit
import AVFoundation

struct WidgetThemeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // Reusing the premium background for a nice aesthetic touch
            Image("img_premium_bg")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.8)

            VStack(spacing: 0) {
                header

                Spacer()

                VStack(spacing: 40) {
                    videoPreview

                    VStack(spacing: 12) {
                        Text("Personalize Your Space")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.label))
                        
                        Text("Choose from a variety of beautiful themes and widgets to match your everyday aesthetic.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                }

                Spacer()
                Spacer() // Extra spacer to balance the layout slightly upwards
            }
            .padding(.bottom, 12)
        }
        .onAppear {
            setupPlayer()
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Widget Theme")
                .font(.system(size: 20, weight: .semibold, design: .rounded))

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Video Preview

    private var videoPreview: some View {
        ZStack {
            if let player = player {
                LoopingPlayerView(player: player)
                    .disabled(true)
            } else {
                Color.gray.opacity(0.1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 40)
        // Set a reasonable aspect ratio or frame if needed, e.g. .aspectRatio(0.8, contentMode: .fit)
        // Here we just let it take available space and pad it.
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "widget_intro", withExtension: "mov") else {
            print("Could not find widget_intro.mov")
            return
        }
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        // Use playerLooper to seamlessly loop the video
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
        self.player = queuePlayer
    }
}

// MARK: - Custom Looping Player View (No Controls)
struct LoopingPlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

#Preview {
    WidgetThemeView()
}
