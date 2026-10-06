import SwiftUI

struct MoodSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showMoodsHomeFloatingButton") private var showHomeFloatingButton: Bool = true
    @EnvironmentObject private var themeManager: AppThemeManager
    
    private struct IdentifiableURL: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }
    
    @State private var exportedFile: IdentifiableURL? = nil
    @State private var showPremiumUpgrade: Bool = false
    
    private var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremium")
    }
    private let pageBackground = Color.pageSurface
    private let cardBackground = Color.cardSurface
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(inkPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Spacer()
                Text("Settings")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(inkPrimary)
                Spacer()
                // Invisible placeholder to center the title
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(pageBackground.ignoresSafeArea(edges: .top))
            
            ScrollView {
                VStack(spacing: 12) {
                    // Floating button toggle
                    HStack {
                        Text("Home Floating Button")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(inkPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $showHomeFloatingButton)
                            .tint(themeManager.primaryColor)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
                    
                    // Export button
                    Button(action: {
                        if isPremium {
                            exportCSV()
                        } else {
                            showPremiumUpgrade = true
                        }
                    }) {
                        HStack {
                            Text("Export")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(inkPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.gray.opacity(0.4))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(pageBackground.ignoresSafeArea())
        }
        .sheet(item: $exportedFile) { file in
            ShareSheet(items: [file.url])
        }
        .fullScreenCover(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
    
    private func exportCSV() {
        let entries = MoodStore.loadAll().sorted(by: { $0.date > $1.date })
        var csv = "Time,Mood,Note\n"
        
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        
        for entry in entries {
            let timeStr = f.string(from: entry.date)
            let moodStr = entry.moodRawValue.capitalized
            let noteStr = entry.note.replacingOccurrences(of: "\"", with: "\"\"")
            
            let escapedNote = noteStr.contains(",") || noteStr.contains("\n") ? "\"\(noteStr)\"" : noteStr
            
            csv += "\(timeStr),\(moodStr),\(escapedNote)\n"
        }
        
        let filename = "MoodLogs.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportedFile = IdentifiableURL(url: url)
        } catch {
            print("Failed to write MoodLogs CSV: \(error)")
        }
    }
}

#Preview {
    MoodSettingsView()
        .environmentObject(AppThemeManager())
}
