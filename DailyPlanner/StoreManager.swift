//
//  StoreManager.swift
//  DailyPlanner
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let freeHabitLimit = 6

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var purchasedProductID: String? = nil
    @Published private(set) var isLoading: Bool = true
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    // Replace with your actual product IDs
    private let productIDs = [
        "com.hevin.habit.weekly",
        "com.hevin.habit.monthly",
        "com.hevin.habit.yearly"
    ]
    
    init() {
        // Start listening to transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Fetch Products
    @MainActor
    func requestProducts() async {
        isLoading = true
        do {
            let storeProducts = try await Product.products(for: productIDs)
            
            // Sort by price or let it be in order.
            // Usually it's better to sort to ensure consistent display.
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Deliver content to user
            await updateCustomerProductStatus()
            
            // Finish transaction
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        // This triggers the App Store to sync entitlements
        try? await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Deliver content to user
                    await self.updateCustomerProductStatus()
                    
                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // MARK: - Check Status
    @MainActor
    func updateCustomerProductStatus() async {
        var hasPremium = false
        var activeProductID: String? = nil
        
        // Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // If product is one of the premium IDs, grant access.
                if productIDs.contains(transaction.productID) {
                    hasPremium = true
                    activeProductID = transaction.productID
                }
            } catch {
                print("Failed to verify transaction")
            }
        }
        
        self.isPremium = hasPremium
        self.purchasedProductID = activeProductID
        
        print("Updated Premium Status: \(hasPremium)")
        
        // Optionally save to UserDefaults if you want synchronous checks elsewhere
        UserDefaults.standard.set(hasPremium, forKey: "isPremium")
    }
    
    // MARK: - Verification
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
