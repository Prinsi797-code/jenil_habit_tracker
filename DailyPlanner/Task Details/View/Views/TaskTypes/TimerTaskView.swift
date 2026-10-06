//
//  TimerTaskView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import AVFoundation
 
struct TimerBody: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @AppStorage("timerSelectedSound") private var selectedSound: String = "Tick"
    @AppStorage("timerStyle") private var timerStyle: String = "circle"
    @State private var showSoundSelection: Bool = false
 
    var body: some View {
        VStack(spacing: 40) {
            HStack(spacing: 40) {
                Button(action: {
                    withAnimation {
                        timerStyle = (timerStyle == "circle") ? "flip" : "circle"
                    }
                }) {
                    IconLabel(systemIcon: "clock", label: "Style")
                }
                .buttonStyle(.plain)
                
                Button(action: { showSoundSelection = true }) {
                    IconLabel(systemIcon: "music.note", label: "Sound")
                }
                .buttonStyle(.plain)
            }
            if timerStyle == "circle" {
                ZStack {
                    Circle()
                        .stroke(viewModel.accentColor.opacity(0.9), lineWidth: 16)
                        .frame(width: 280, height: 280)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .offset(y: -140)
                    Text(viewModel.countdownText)
                        .font(.system(size: 44, weight: .bold))
                }
            } else {
                FlipClockView(timeText: viewModel.countdownText, color: viewModel.accentColor)
            }
        }
        .sheet(isPresented: $showSoundSelection) {
            MusicSelectionView(selectedSound: $selectedSound)
                .presentationDetents([.fraction(0.6)])
        }
    }
}
 
struct TimerFooter: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @State private var showNumberPad = false
 
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 20) {
                Button(action: { viewModel.reset() }) {
                    Circle().fill(Color.white.opacity(0.6))
                        .frame(width: 52, height: 52)
                        .overlay(Image(systemName: "arrow.counterclockwise"))
                }
                .buttonStyle(.plain)
                
                Button(action: viewModel.toggleTimer) {
                    Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 190, height: 52)
                        .background(viewModel.accentColor)
                        .clipShape(Capsule())
                }
                
                Button(action: { showNumberPad = true }) {
                    Circle().fill(Color.white.opacity(0.6))
                        .frame(width: 52, height: 52)
                        .overlay(Image(systemName: "plus"))
                }
                .buttonStyle(.plain)
            }

            MemoStatRow()
        }
        .sheet(isPresented: $showNumberPad) {
            TimerNumberPadView(accentColor: viewModel.accentColor) { value in
                viewModel.add(value)
            }
            .presentationDetents([.fraction(0.55)])
        }
    }
}

struct MusicSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedSound: String
    
    let sounds = ["Tick", "Cafe", "Faraway", "Fire", "Forests", "Ocean", "Water"]
    
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationStack {
            List(sounds, id: \.self) { sound in
                Button {
                    selectedSound = sound
                    playSound(named: sound)
                } label: {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(selectedSound == sound ? .blue : .primary)
                        Text(sound)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        audioPlayer?.stop()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }
    
    private func playSound(named name: String) {
        audioPlayer?.stop()
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}

struct FlipClockView: View {
    let timeText: String
    let color: Color
    
    var body: some View {
        let components = timeText.split(separator: ":").map(String.init)
        
        VStack(spacing: 16) {
            ForEach(0..<components.count, id: \.self) { row in
                let comp = components[row]
                let chars = Array(comp)
                HStack(spacing: 16) {
                    let d1 = chars.count >= 2 ? String(chars[0]) : "0"
                    let d2 = chars.count >= 2 ? String(chars[1]) : (chars.count == 1 ? String(chars[0]) : "0")
                    
                    FlipDigitView(digit: d1, color: color)
                    FlipDigitView(digit: d2, color: color)
                }
            }
        }
    }
}

struct FlipDigitView: View {
    let digit: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var oldDigit: String
    @State private var currentDigit: String
    @State private var progress: CGFloat = 1.0
    
    init(digit: String, color: Color) {
        self.digit = digit
        self.color = color
        _oldDigit = State(initialValue: digit)
        _currentDigit = State(initialValue: digit)
    }
    
    var body: some View {
        let bgColor: Color = colorScheme == .dark ? Color(white: 0.12) : Color.white
        
        ZStack {
            // 1. Static Top Half (New Digit)
            HalfDigit(digit: currentDigit, color: color, bgColor: bgColor, isTop: true)
            
            // 2. Static Bottom Half (Old Digit)
            HalfDigit(digit: oldDigit, color: color, bgColor: bgColor, isTop: false)
            
            // 3. Flipping Top Half (Old Digit)
            HalfDigit(digit: oldDigit, color: color, bgColor: bgColor, isTop: true)
                .rotation3DEffect(
                    .degrees(Double(progress) * -180),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    perspective: 0.5
                )
                .opacity(progress < 0.5 ? 1 : 0)
                .zIndex(1)
            
            // 4. Flipping Bottom Half (New Digit)
            HalfDigit(digit: currentDigit, color: color, bgColor: bgColor, isTop: false)
                .rotation3DEffect(
                    .degrees(90 - Double(progress - 0.5) * 180),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    perspective: 0.5
                )
                .opacity(progress >= 0.5 ? 1 : 0)
                .zIndex(1)
            
            // Center Divider Line
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 2)
                Spacer()
            }
        }
        .frame(width: 120, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 10, y: 4)
        .onChange(of: digit) { newValue in
            if newValue != currentDigit {
                oldDigit = currentDigit
                currentDigit = newValue
                progress = 0
                withAnimation(.linear(duration: 0.25)) {
                    progress = 1.0
                }
            }
        }
    }
}

struct HalfDigit: View {
    let digit: String
    let color: Color
    let bgColor: Color
    let isTop: Bool
    
    var body: some View {
        Text(digit)
            .font(.system(size: 85, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .frame(width: 120, height: 160)
            .background(bgColor)
            .clipShape(HalfShape(isTop: isTop))
    }
}

struct HalfShape: Shape {
    let isTop: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isTop {
            path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: rect.height / 2))
        } else {
            path.addRect(CGRect(x: 0, y: rect.height / 2, width: rect.width, height: rect.height / 2))
        }
        return path
    }
}
