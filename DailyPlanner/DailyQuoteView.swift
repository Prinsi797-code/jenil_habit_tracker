//
//  DailyQuoteView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 29/07/26.
//

import SwiftUI
import Photos
 
// MARK: - Quote model
 
struct QuoteItem: Identifiable {
    let id = UUID()
    let text: String
    let imageName: String
    var remoteImageURL: URL? = nil
}
 
// MARK: - Full-screen quote viewer
 
struct DailyQuoteView: View {
    @State var quotes: [QuoteItem]
 
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var imageIndex: Int
    @State private var quoteIndex: Int
    @State private var showShareSheet: Bool = false
    @State private var isLoading: Bool = false
    @State private var loadError: String? = nil
    
    @State private var shareItems: [Any] = []
    @State private var isPreparingShare: Bool = false
    
    @State private var showDownloadConfirmAlert: Bool = false
    @State private var showDownloadResultAlert: Bool = false
    @State private var downloadResultMessage: String = ""
    @State private var isDownloading: Bool = false
 
    init(quotes: [QuoteItem] = [], initialIndex: Int = 0) {
        self.quotes = quotes

        let index = quotes.indices.contains(initialIndex) ? initialIndex : 0

        _imageIndex = State(initialValue: index)
        _quoteIndex = State(initialValue: index)
    }
 
    private var currentImage: QuoteItem? {
        quotes.indices.contains(imageIndex) ? quotes[imageIndex] : nil
    }

    private var currentQuote: QuoteItem? {
        quotes.indices.contains(quoteIndex) ? quotes[quoteIndex] : nil
    }

    // MARK: - Responsive helpers

    /// Scales side margins with screen width so content breathes on
    /// small phones, regular phones, and iPad alike.
    private func sideMargin(for width: CGFloat) -> CGFloat {
        guard width.isFinite && width >= 0 else { return 16 }
        switch width {
        case ..<360:      return 16   // small phones (e.g. SE)
        case 360..<430:   return 24   // standard/large phones
        default:          return max(48, width * 0.12) // iPad / regular size class
        }
    }

    private func contentMaxWidth(for width: CGFloat) -> CGFloat {
        guard width.isFinite && width >= 0 else { return 0 }
        let w = width - 2 * sideMargin(for: width)
        return max(0, min(w, 560))
    }
 
    var body: some View {
        GeometryReader { geo in
            let margin = sideMargin(for: geo.size.width)
            let maxContentWidth = contentMaxWidth(for: geo.size.width)

            ZStack {
                background

                VStack(spacing: 0) {

                    // MARK: Top Bar
                    topBar
                        .frame(maxWidth: maxContentWidth)
                        .padding(.horizontal, margin)
                        .padding(.top, geo.safeAreaInsets.top + 70)

                    Spacer()

                    // MARK: Quote
                    Group {
                        if isLoading {

                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.3)

                        } else if let error = loadError {

                            VStack(spacing: 12) {

                                Text("Couldn't load quotes")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)

                                Button("Retry") {
                                    Task {
                                        await loadFromAPI()
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                            }
                            .frame(maxWidth: maxContentWidth)

                        } else if let current = currentQuote {

                            Text(current.text)
                                .font(.system(size: dynamicQuoteFontSize(for: geo.size.width),
                                              weight: .semibold,
                                              design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .frame(maxWidth: maxContentWidth)
                                .shadow(color: .black.opacity(0.35),
                                        radius: 8,
                                        x: 0,
                                        y: 2)

                        } else {

                            Text("No Quotes")
                                .foregroundColor(.white)

                        }
                    }
                    .padding(.horizontal, margin)
                    .frame(maxWidth: .infinity)

                    Spacer()

                    // MARK: Bottom Buttons
                    if !quotes.isEmpty {

                        actionBar
                            .frame(maxWidth: maxContentWidth)
                            .padding(.horizontal, margin)
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 30))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .task {
            if quotes.isEmpty {
                await loadFromAPI()
            }
        }
        .alert("Save Image", isPresented: $showDownloadConfirmAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task { await download() }
            }
        } message: {
            Text("Save this image to your Photos?")
        }
        .alert("Download", isPresented: $showDownloadResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(downloadResultMessage)
        }
    }

    /// Slightly larger type on iPad / wide screens, smaller on compact phones.
    private func dynamicQuoteFontSize(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<360:    return 21
        case 360..<430: return 24
        default:        return 30
        }
    }
 
    // MARK: Background
 
    @ViewBuilder
    private var background: some View {
        ZStack {
            if let current = currentImage, let remoteURL = current.remoteImageURL {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    case .failure(let error):
                        fallbackGradient
                            .onAppear {
                                print("🔴 [DailyQuoteView] AsyncImage failed for \(remoteURL.absoluteString): \(error)")
                            }
                    case .empty:
                        fallbackGradient
                    @unknown default:
                        fallbackGradient
                    }
                }
            } else if let current = currentImage, !current.imageName.isEmpty, let uiImage = UIImage(named: current.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                fallbackGradient
            }
 
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.05), location: 0.45),
                    .init(color: Color(red: 0.55, green: 0.42, blue: 0.34).opacity(0.55), location: 0.62),
                    .init(color: Color(red: 0.45, green: 0.34, blue: 0.28).opacity(0.92), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
 
    private var fallbackGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.55, green: 0.72, blue: 0.90), Color(red: 0.93, green: 0.60, blue: 0.70)],
            startPoint: .top, endPoint: .bottom
        )
    }
 
    // MARK: Top bar
 
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 35, height: 35)
            }
            Spacer()
        }
    }
 
    // MARK: Action bar
 
    private var actionBar: some View {
        HStack {
            toolButton(systemImage: "arrow.down.to.line") {
                showDownloadConfirmAlert = true
            }

            Spacer(minLength: 12)

            toolButton(systemImage: "square.and.arrow.up") {
                Task { await prepareAndShowShare() }
            }

            Spacer(minLength: 12)

            toolButton(systemImage: "shuffle", action: shuffle)

            Spacer(minLength: 12)

            toolButton(systemImage: "forward.fill", action: goNext)
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }
    
    private func prepareAndShowShare() async {
        guard let quote = currentQuote else { return }
        isPreparingShare = true
        defer { isPreparingShare = false }
        AnalyticsManager.shared.logQuoteShared()

        var uiImage: UIImage? = nil

        if let current = currentImage {
            if let remoteURL = current.remoteImageURL {
                do {
                    let (data, _) = try await URLSession.shared.data(from: remoteURL)
                    uiImage = UIImage(data: data)
                } catch {
                    print("🔴 Share image fetch failed: \(error)")
                }
            } else if !current.imageName.isEmpty {
                uiImage = UIImage(named: current.imageName)
            }
        }

        let card = QuoteShareCard(text: quote.text, uiImage: uiImage)

        if let composed = await Self.renderToImage(card, size: CGSize(width: 1080, height: 1350)) {
            shareItems = [composed, quote.text]
        } else {
            shareItems = [quote.text] // fallback to text-only if rendering fails
        }

        showShareSheet = true
    }

    /// Renders a SwiftUI view to a UIImage reliably by briefly attaching it to a
    /// real UIWindow/UIHostingController. A bare `ImageRenderer` can return the
    /// background but silently drop `Text`/overlay content if the view hasn't
    /// actually been laid out in a window yet — this forces a real layout pass
    /// first, so text is guaranteed to be present in the snapshot.
    @MainActor
    private static func renderToImage<V: View>(_ view: V, size: CGSize) async -> UIImage? {
        let hostingController = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        hostingController.view.bounds = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .clear

        // Attach to an offscreen window so the hierarchy actually lays out
        // (fonts, images, and text all resolve properly).
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = hostingController
        window.isHidden = false
        window.makeKeyAndVisible()

        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        // Give SwiftUI/AsyncImage-backed content one more run-loop tick to settle
        // before snapshotting, since layout can complete before rendering does.
        await Task.yield()
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }

        // Tear down the offscreen window.
        window.isHidden = true
        window.rootViewController = nil

        return image
    }
 
    private func toolButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.18))
                )
        }
    }
 
    // MARK: API loading
 
    private func loadFromAPI() async {
        print("🟡 [DailyQuoteView] loadFromAPI() started")
        isLoading = true
        loadError = nil
        defer { isLoading = false }
 
        do {
            let items = try await QuoteImageService.shared.fetchQuoteItems()
            print("🟢 [DailyQuoteView] loadFromAPI() succeeded with \(items.count) item(s)")
            self.quotes = items
            self.imageIndex = 0
            self.quoteIndex = 0
        } catch {
            print("🔴 [DailyQuoteView] loadFromAPI() failed: \(error)")
            if let urlError = error as? URLError {
                print("🔴 [DailyQuoteView] URLError code=\(urlError.code.rawValue): \(urlError.localizedDescription)")
                self.loadError = urlError.localizedDescription
            } else {
                self.loadError = error.localizedDescription
            }
        }
    }
 
    // MARK: Actions
 
    /// Requests Photos "add only" permission, fetches/loads the current image,
    /// composes it with the quote text (same look as the share card), saves the
    /// composed image to the user's Photo library, and reports success/failure via alert.
    private func download() async {
        guard let current = currentImage else { return }
        let quoteText = currentQuote?.text ?? ""
        isDownloading = true
        defer { isDownloading = false }

        // Request photo library "add only" permission (iOS 14+)
        let status = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }

        guard status == .authorized || status == .limited else {
            downloadResultMessage = "Please allow Photos access in Settings to save images."
            showDownloadResultAlert = true
            return
        }

        var uiImage: UIImage? = nil

        if let remoteURL = current.remoteImageURL {
            do {
                let (data, _) = try await URLSession.shared.data(from: remoteURL)
                uiImage = UIImage(data: data)
            } catch {
                print("🔴 [DailyQuoteView] Download fetch failed: \(error)")
                downloadResultMessage = "Couldn't download the image. Please check your connection and try again."
                showDownloadResultAlert = true
                return
            }
        } else if !current.imageName.isEmpty {
            uiImage = UIImage(named: current.imageName)
        }

        guard uiImage != nil else {
            downloadResultMessage = "This image couldn't be prepared for saving."
            showDownloadResultAlert = true
            return
        }

        // Compose the photo + quote text into a single image, same as the share card.
        let card = QuoteShareCard(text: quoteText, uiImage: uiImage)

        guard let imageToSave = await Self.renderToImage(card, size: CGSize(width: 1080, height: 1350)) else {
            downloadResultMessage = "This image couldn't be prepared for saving."
            showDownloadResultAlert = true
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
            }
            downloadResultMessage = "Image saved to your Photos."
        } catch {
            print("🔴 [DailyQuoteView] Save to Photos failed: \(error)")
            downloadResultMessage = "Couldn't save the image: \(error.localizedDescription)"
        }

        showDownloadResultAlert = true
    }
    
    private struct QuoteShareCard: View {
        let text: String
        let uiImage: UIImage?

        var body: some View {
            ZStack {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.55, green: 0.72, blue: 0.90),
                                 Color(red: 0.93, green: 0.60, blue: 0.70)],
                        startPoint: .top, endPoint: .bottom
                    )
                }

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.05), location: 0.45),
                        .init(color: Color(red: 0.55, green: 0.42, blue: 0.34).opacity(0.55), location: 0.62),
                        .init(color: Color(red: 0.45, green: 0.34, blue: 0.28).opacity(0.92), location: 1.0)
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                Text(text)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
            }
            .frame(width: 1080, height: 1350) // portrait, good for IG/story-style shares
            .clipped()
        }
    }
 
    private func shuffle() {
        guard quotes.count > 1 else { return }

        var newIndex = imageIndex

        while newIndex == imageIndex {
            newIndex = Int.random(in: quotes.indices)
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            imageIndex = newIndex
        }
    }
 
    private func goNext() {
        guard !quotes.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            quoteIndex = (quoteIndex + 1) % quotes.count
        }
    }
 
    private func goPrevious() {
        guard !quotes.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            quoteIndex = (quoteIndex - 1 + quotes.count) % quotes.count
        }
    }
}
 
#Preview {
    DailyQuoteView()
}
