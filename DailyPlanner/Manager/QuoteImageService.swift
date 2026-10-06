//
//  QuoteImageService.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 29/07/26.
//

import Foundation
 
// MARK: - API response models
 
struct QuoteImageResponse: Decodable {
    let status: String
    let count: Int
    let data: [QuoteImageEntry]
}
 
struct QuoteImageEntry: Decodable, Identifiable {
    let id: Int
    let image: String
 
    var url: URL? { URL(string: image) }
}
 
struct QuoteTextResponse: Decodable {
    let status: String
    let count: Int
    let data: [QuoteTextEntry]
}
 
struct QuoteTextEntry: Decodable, Identifiable {
    let id: Int
    let quote: String
}
 
// MARK: - Service
 
enum QuoteImageServiceError: Error {
    case badStatus(Int?)
    case emptyData
}
 
final class QuoteImageService {
 
    static let shared = QuoteImageService()
 
    private let imageEndpoint = URL(string: "https://calendar.adinsignia.com/image.php")!
    private let quoteEndpoint = URL(string: "https://calendar.adinsignia.com/quote.php")!
 
    /// Flip to false to silence all logs from this service.
    var isDebugLoggingEnabled = true
 
    private func log(_ message: String) {
        guard isDebugLoggingEnabled else { return }
        print("🟣 [QuoteImageService] \(message)")
    }
 
    // MARK: image.php
 
    func fetchImages() async throws -> [QuoteImageEntry] {
        log("➡️ GET \(imageEndpoint.absoluteString)")
        let startedAt = Date()
        
        let (data, response) = try await URLSession.shared.data(from: imageEndpoint)
        let elapsed = String(format: "%.2f", Date().timeIntervalSince(startedAt))
        
        let http = response as? HTTPURLResponse
        log("⬅️ image.php status=\(http?.statusCode ?? -1) bytes=\(data.count) time=\(elapsed)s")
        
        if let raw = String(data: data, encoding: .utf8) {
            log("📦 image.php raw: \(raw)")
        }
        
        guard let http, (200..<300).contains(http.statusCode) else {
            log("❌ image.php bad status")
            throw QuoteImageServiceError.badStatus(http?.statusCode)
        }
        
        let decoded = try JSONDecoder().decode(QuoteImageResponse.self, from: data)
        log("✅ image.php decoded \(decoded.data.count) entries")
        
        guard !decoded.data.isEmpty else { throw QuoteImageServiceError.emptyData }
        return decoded.data
    }
 
    // MARK: quote.php
 
    func fetchQuoteTexts() async throws -> [QuoteTextEntry] {
        log("➡️ GET \(quoteEndpoint.absoluteString)")
        let startedAt = Date()
        
        let (data, response) = try await URLSession.shared.data(from: quoteEndpoint)
        let elapsed = String(format: "%.2f", Date().timeIntervalSince(startedAt))
        
        let http = response as? HTTPURLResponse
        log("⬅️ quote.php status=\(http?.statusCode ?? -1) bytes=\(data.count) time=\(elapsed)s")
        
        if let raw = String(data: data, encoding: .utf8) {
            log("📦 quote.php raw: \(raw)")
        }
        
        guard let http, (200..<300).contains(http.statusCode) else {
            log("❌ quote.php bad status")
            throw QuoteImageServiceError.badStatus(http?.statusCode)
        }
        
        let decoded = try JSONDecoder().decode(QuoteTextResponse.self, from: data)
        log("✅ quote.php decoded \(decoded.data.count) entries")
        
        guard !decoded.data.isEmpty else { throw QuoteImageServiceError.emptyData }
        return decoded.data
    }
 
    // MARK: Combined
 
    private var cachedQuotes: [QuoteItem]?
    
    /// Fetches both endpoints in parallel and pairs images with quotes,
    /// cycling through whichever list is shorter. Caches results in-memory.
    func fetchQuoteItems() async throws -> [QuoteItem] {
        if let cached = cachedQuotes {
            log("⚡️ returning \(cached.count) cached QuoteItem(s)")
            return cached
        }
        
        log("🔄 fetching image.php + quote.php in parallel")
        async let images = fetchImages()
        async let texts = fetchQuoteTexts()
 
        let (imageList, textList) = try await (images, texts)
        log("🔗 pairing \(imageList.count) images with \(textList.count) quotes")
 
        let items = imageList.enumerated().map { index, entry -> QuoteItem in
            let text = textList[index % textList.count].quote
            return QuoteItem(text: text, imageName: "", remoteImageURL: entry.url)
        }
 
        log("✅ produced \(items.count) QuoteItem(s)")
        self.cachedQuotes = items
        return items
    }
}
