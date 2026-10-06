import SwiftUI
import StoreKit

struct ProfileHeaderView: View {
    @AppStorage("userProfileName") private var name: String = "No Name"
    @State private var isEditingName: Bool = false
    @FocusState private var isNameFocused: Bool
    
    @AppStorage("userProfileImageData") private var profileImageData: Data?
    
    @State private var profileImage: UIImage? = nil
    @State private var showImageSourceDialog: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var activePickerSource: UIImagePickerController.SourceType? = nil
    @State private var showCameraUnavailableAlert: Bool = false
    let addedHabits: [HabitSummary]
    
    @EnvironmentObject private var themeManager: AppThemeManager
    
    private var pinkRed: Color { themeManager.primaryColor }
    private let inkPrimary = Color(.label)
    private let inkMuted = Color(.tertiaryLabel)
    private let avatarRing = Color(red: 1.0, green: 0.80, blue: 0.30)
    private let cardSurface = Color.cardSurface
    
    var body: some View {
        HStack {
            Button {
                showImageSourceDialog = true
            } label: {
                ZStack {
                    Circle()
                        .stroke(avatarRing, lineWidth: 2.5)
                        .frame(width: 64, height: 64)
                    
                    if let profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(cardSurface)
                            .frame(width: 58, height: 58)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(inkMuted)
                            )
                    }
                    
                    // Small camera badge to hint it's tappable
                    Circle()
                        .fill(pinkRed)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 22, y: 22)
                }
            }
            .buttonStyle(.plain)
            
            if isEditingName {
                TextField("Name", text: $name, onCommit: { isEditingName = false })
                    .focused($isNameFocused)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                    .padding(.leading, 12)
                    .onAppear {
                        isNameFocused = true
                    }
            } else {
                Button(action: { isEditingName = true }) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(inkPrimary)
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(inkPrimary)
                    }
                }
                .padding(.leading, 12)
            }
            
            Spacer()
            
            NavigationLink {
                MoreSettingsView(addedHabits: addedHabits)
            } label: {
                Image(systemName: "hexagon")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(inkPrimary)
                    .overlay(
                        Circle().fill(inkPrimary).frame(width: 4, height: 4)
                    )
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            if let data = profileImageData, let img = UIImage(data: data) {
                profileImage = img
            }
        }
        .onChange(of: profileImage) { newValue in
            if let newValue, let data = newValue.jpegData(compressionQuality: 0.8) {
                profileImageData = data
            }
        }
        .confirmationDialog("Update Profile Photo", isPresented: $showImageSourceDialog, titleVisibility: .visible) {
            Button("Camera") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    activePickerSource = .camera
                    showImagePicker = true
                } else {
                    showCameraUnavailableAlert = true
                }
            }
            Button("Photo Gallery") {
                activePickerSource = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device doesn't support camera access.")
        }
        .sheet(isPresented: $showImagePicker) {
            if let source = activePickerSource {
                ImagePicker(sourceType: source, selectedImage: $profileImage)
                    .ignoresSafeArea()
            }
        }
    }
}

struct PremiumBannerView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    @Binding var showPremiumUpgrade: Bool
    
    private var pinkRed: Color { themeManager.primaryColor }
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    
    var body: some View {
        Button(action: {
            showPremiumUpgrade = true
        }) {
            HStack(spacing: 14) {
                Image("ic_crown")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(inkPrimary)
                    Text("Get a bit better everyday")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(inkSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.cardSurface)
                    .overlay(Capsule().stroke(pinkRed.opacity(0.4), lineWidth: 1.5))
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Moods Component Models

struct MoodDay: Identifiable {
    let id = UUID()
    let label: String
    let date: Int
    let actualDate: Date
    var moodColor: Color? = nil
    var moodImageName: String? = nil
}

struct MoodsCardView: View {
    @State private var showMoods: Bool = false
    @State private var allMoodEntries: [MoodEntry] = []
    
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    
    private var moodWeek: [MoodDay] {
        var days = Self.generateCurrentWeek()
        
        let entriesByDate: [DateComponents: MoodType] = allMoodEntries.reduce(into: [:]) { dict, entry in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: entry.date)
            if let type = MoodType(rawValue: entry.moodRawValue.capitalized) {
                dict[components] = type
            }
        }
        
        for i in 0..<days.count {
            let dayComps = Calendar.current.dateComponents([.year, .month, .day], from: days[i].actualDate)
            if let type = entriesByDate[dayComps] {
                days[i].moodColor = type.color
                days[i].moodImageName = type.imageName
            }
        }
        
        return days
    }
    
    var body: some View {
        Button(action: {
            showMoods = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Moods")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(inkPrimary)
                    Spacer()
                    HStack(spacing: 3) {
                        Text("View")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(inkSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(inkSecondary)
                    }
                    .padding(.leading, 8)
                }
                .padding(.bottom, 14)
                            
                Divider()
                
                HStack {
                    ForEach(moodWeek) { day in
                        moodCell(day)
                        if day.id != moodWeek.last?.id { Spacer(minLength: 0) }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
        .onAppear {
            allMoodEntries = MoodStore.loadAll()
        }
        .navigationDestination(isPresented: $showMoods) {
            MoodsView()
                .onDisappear {
                    allMoodEntries = MoodStore.loadAll()
                }
        }
    }
    
    private func moodCell(_ day: MoodDay) -> some View {
        VStack(spacing: 8) {
            Text(day.label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(inkPrimary)
            
            ZStack {
                if let color = day.moodColor {
                    Image(day.moodImageName ?? "")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                } else {
                    Circle()
                        .strokeBorder(inkMuted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 38, height: 38)
                    Text("\(day.date)")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(inkPrimary)
                }
            }
        }
    }
    
    private static func generateCurrentWeek() -> [MoodDay] {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        
        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: monday) ?? today
            let dayNum = cal.component(.day, from: date)
            return MoodDay(label: labels[i], date: dayNum, actualDate: date)
        }
    }
}

// MARK: - Daily Quote Component

struct DailyQuoteCardView: View {
    @State private var showDailyQuote: Bool = false
    @State private var fetchedQuotes: [QuoteItem] = []
    @State private var isLoadingQuotes: Bool = false
    
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    
    private let fallbackQuotes: [QuoteItem] = [
        QuoteItem(text: "I am confident in my ability to make wise decisions for myself.", imageName: "quote_bg_1"),
        QuoteItem(text: "I am capable of overcoming any obstacles in my path.", imageName: "quote_bg_2")
    ]
    
    private var todayQuote: QuoteItem? {
        let pool = fetchedQuotes.isEmpty ? fallbackQuotes : fetchedQuotes
        guard !pool.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return pool[(dayOfYear - 1) % pool.count]
    }
    
    private var todayQuoteImageURL: URL? {
        todayQuote?.remoteImageURL
    }
    
    private var todayQuoteIndex: Int {
        let pool = fetchedQuotes.isEmpty ? fallbackQuotes : fetchedQuotes
        guard !pool.isEmpty else { return 0 }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return (dayOfYear - 1) % pool.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Daily Quote")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                Spacer()
                Button(action: {
                    print("Tap Daily Quote")
                    showDailyQuote = true
                }) {
                    HStack(spacing: 3) {
                        Text("View").font(.system(size: 15, design: .rounded)).foregroundColor(inkSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(inkSecondary)
                    }
                }
            }
            
            Divider().padding(.vertical, 14)
            Button(action: { showDailyQuote = true }) {
                ZStack(alignment: .center) {
                    if let imageURL = todayQuoteImageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                quoteCardFallbackGradient
                            }
                        }
                    } else {
                        quoteCardFallbackGradient
                    }
                    
                    Color.black.opacity(0.3)
                    
                    if isLoadingQuotes {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(todayQuote?.text ?? "I am confident in my ability to make wise decisions for myself.")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 1)
                            .padding(16)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .padding(.horizontal, 20)
        .task {
            await loadDailyQuotes()
        }
        .fullScreenCover(isPresented: $showDailyQuote) {
            DailyQuoteView(
                quotes: fetchedQuotes.isEmpty ? fallbackQuotes : fetchedQuotes,
                initialIndex: todayQuoteIndex
            )
        }
    }
    
    private var quoteCardFallbackGradient: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.72, blue: 0.90), Color(red: 0.93, green: 0.60, blue: 0.70)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(height: 100)
    }
    
    private func loadDailyQuotes() async {
        guard fetchedQuotes.isEmpty else { return }
        isLoadingQuotes = true
        defer { isLoadingQuotes = false }
        
        do {
            let items = try await QuoteImageService.shared.fetchQuoteItems()
            fetchedQuotes = items
        } catch {
            print("🔴 [DailyQuoteCardView] Failed to load daily quotes: \(error)")
        }
    }
}

// MARK: - Settings Component Models

fileprivate struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    var value: String? = nil
    var action: () -> Void = {}
}

fileprivate struct SettingsAppPromo: Identifiable {
    let id = UUID()
    let image: String
    let name: String
    let appStoreURL: String
}

// MARK: - Extra Cards

struct SettingsCardsView: View {
    let addedHabits: [HabitSummary]
    
    @State private var showWidgetTheme: Bool = false
    @State private var showHabitManager: Bool = false
    @State private var showThemeSettings: Bool = false
    @State private var showUsageTips: Bool = false
    
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)
    private let inkMuted = Color(.tertiaryLabel)
    
    private let settingsRows: [SettingsItem] = [
        SettingsItem(title: "Habit Manager"),
        SettingsItem(title: "Widget Theme"),
        SettingsItem(title: "Theme")
    ]
    
    private var aboutRows: [SettingsItem] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return [
            SettingsItem(title: "Usage Tips"),
            SettingsItem(title: "Privacy Policy"),
            SettingsItem(title: "Share", action: {
                if let url = URL(string: "https://apps.apple.com/in/app/habittrack-daily-planner/id6799328376") {
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                       let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        if let popover = activityVC.popoverPresentationController {
                            popover.sourceView = rootVC.view
                            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                            popover.permittedArrowDirections = []
                        }
                        rootVC.present(activityVC, animated: true, completion: nil)
                    }
                }
            }),
            SettingsItem(title: "Review & Support", value: "V \(version)", action: {
                if let url = URL(string: "https://apps.apple.com/in/app/habittrack-daily-planner/id6799328376?action=write-review") {
                    UIApplication.shared.open(url)
                }
            })
        ]
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Settings Card
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(inkPrimary)
                    Spacer()
                    NavigationLink {
                        MoreSettingsView(addedHabits: addedHabits)
                    } label: {
                        HStack(spacing: 3) {
                            Text("More Settings").font(.system(size: 15, design: .rounded)).foregroundColor(inkSecondary)
                            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundColor(inkSecondary)
                        }
                    }
                }
                
                Divider().padding(.vertical, 14)
                
                VStack(spacing: 0) {
                    ForEach(Array(settingsRows.enumerated()), id: \.element.id) { index, row in
                        settingsRow(row)
                        if index != settingsRows.count - 1 {
                            Divider().padding(.vertical, 14)
                        }
                    }
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
            .padding(.horizontal, 20)
            
            // About Card
            VStack(alignment: .leading, spacing: 0) {
                Text("About")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
                
                Divider().padding(.vertical, 14)
                
                VStack(spacing: 0) {
                    ForEach(Array(aboutRows.enumerated()), id: \.element.id) { index, row in
                        settingsRow(row)
                        if index != aboutRows.count - 1 {
                            Divider().padding(.vertical, 14)
                        }
                    }
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showWidgetTheme) {
            WidgetThemeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $showHabitManager) {
            AllHabitsView()
        }
        .navigationDestination(isPresented: $showThemeSettings) {
            ThemeSettingsView()
        }
        .navigationDestination(isPresented: $showUsageTips) {
            UsageTipsView()
        }
    }
    
    private func settingsRow(_ row: SettingsItem) -> some View {
        Button {
            if row.title == "Widget Theme" {
                showWidgetTheme = true
            } else if row.title == "Habit Manager" {
                showHabitManager = true
            } else if row.title == "Theme" {
                showThemeSettings = true
            } else if row.title == "Usage Tips" {
                showUsageTips = true
            } else if row.title == "Privacy Policy" {
                if let url = URL(string: "https://habitplanner.blogspot.com/2026/08/privacy-policy.html") {
                    UIApplication.shared.open(url)
                }
            } else {
                row.action()
            }
        } label: {
            HStack {
                Text(LocalizedStringKey(row.title))
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(inkPrimary)
                Spacer()
                if let value = row.value {
                    Text(value)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(inkSecondary)
                }
                if row.title != "Review & Support" {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(inkMuted)
                }
            }
        }
    }
}

struct OurAppsCardView: View {
    private let inkPrimary = Color(.label)
    
    private let ourApps: [SettingsAppPromo] = [
        SettingsAppPromo(image: "ic_gpsApp", name: "GPS Field", appStoreURL: "https://apps.apple.com/in/app/gps-field-measure-areago/id6791980557"),
        SettingsAppPromo(image: "ic_pedometer", name: "Pedometer", appStoreURL: "https://apps.apple.com/in/app/pedometer-app-step-counter/id6787060827"),
        SettingsAppPromo(image: "ic_calculater", name: "Calculator", appStoreURL: "https://apps.apple.com/in/app/megacalc-calculator/id6758510000"),
        SettingsAppPromo(image: "ic_calender", name: "Calendar", appStoreURL: "https://apps.apple.com/in/app/smart-calendar-2026-to-do/id6756920857"),
        SettingsAppPromo(image: "ic_keyboard", name: "Keyboard", appStoreURL: "https://apps.apple.com/in/app/fonts-keyboard-emoji-themes/id6782760917")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Our Apps")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(inkPrimary)
            
            Divider().padding(.vertical, 14)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(ourApps) { app in
                        Button {
                            guard let url = URL(string: app.appStoreURL) else { return }
                            UIApplication.shared.open(url)
                        } label: {
                            VStack(spacing: 8) {
                                Image(app.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))

                                Text(app.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(inkPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.cardSurface))
        .padding(.horizontal, 20)
    }
}

// MARK: - UIImagePickerController wrapper

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.selectedImage = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.selectedImage = original
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
