//
//  PremiumUpgradeView.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {

    @Environment(\.dismiss) private var dismiss

    private enum Plan: String, CaseIterable, Identifiable {
        case weekly, monthly, yearly
        var id: String { rawValue }

        var title: String {
            switch self {
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }

        var suffix: String {
            switch self {
            case .weekly: return "/wk"
            case .monthly: return "/mo"
            case .yearly: return "/yr"
            }
        }
        
        var fallbackPrice: String {
            switch self {
            case .weekly: return "--/wk"
            case .monthly: return "--/mo"
            case .yearly: return "--/yr"
            }
        }

        var badge: String? {
            switch self {
            case .weekly: return nil
            case .monthly: return nil
            case .yearly: return "Save 77%"
            }
        }

        var subtitle: String {
            switch self {
            case .weekly: return "Billed weekly"
            case .monthly: return "Billed monthly"
            case .yearly: return "Billed yearly"
            }
        }
    }

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }

    private let features: [Feature] = [
        Feature(icon: "nosign", title: "Remove Ads", subtitle: "Enjoy an uninterrupted, ad-free experience"),
        Feature(icon: "paintpalette.fill", title: "Exclusive Themes", subtitle: "Unlock every widget theme and color palette"),
        Feature(icon: "square.text.square.fill", title: "Advanced Reports", subtitle: "Export detailed history and insights anytime"),
        Feature(icon: "bell.badge.fill", title: "Smart Reminders", subtitle: "Personalized nudges based on your routine"),
    ]

    @EnvironmentObject private var themeManager: AppThemeManager
    @EnvironmentObject private var storeManager: StoreManager
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var purchaseErrorMessage: String = ""

    private var pinkRed: Color { themeManager.primaryColor }
    private let peach = Color(red: 0.99, green: 0.56, blue: 0.42)
    private let inkPrimary = Color(.label)
    private let inkSecondary = Color(.secondaryLabel)

    private var pinkGradient: LinearGradient {
        themeManager.horizontalGradient
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.pageSurface.ignoresSafeArea()
            
            Image("img_premium_bg")
                .resizable()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    header
                    planPicker
                    featureList
                    
                    // Manage Subscription link for premium users
                    if storeManager.isPremium {
                        manageSubscriptionLink
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 140)
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                ctaFooter
            }
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
        .onAppear {
            AnalyticsManager.shared.logPremiumPaywallViewed()
        }
    }

    // MARK: - Close button

    private var closeButton: some View {
        Button(action: {
            AnalyticsManager.shared.logPaywallDismissed()
            dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(inkPrimary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.cardSurface))
        }
    }

    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            
            VStack(spacing: 4) {
                (
                    Text("Unlock ")
                        .foregroundColor(inkPrimary)
                    + Text("Pro")
                        .foregroundColor(pinkRed)
                    + Text(" now")
                        .foregroundColor(inkPrimary)
                )
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.top, 100)
                
                Text("Become better every day!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(inkPrimary)
            }
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(spacing: 14) {
            ForEach(features) { feature in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(pinkRed.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: feature.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(pinkRed)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(inkPrimary)
                        Text(feature.subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(inkSecondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.cardSurface))
    }

    // MARK: - Plan picker

    private var planPicker: some View {
        VStack(spacing: 12) {
            if storeManager.isLoading {
                // Skeleton loading state
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.cardSurface)
                        .frame(height: 80)
                        .overlay(
                            HStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 22, height: 22)
                                VStack(alignment: .leading, spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 80, height: 14)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 120, height: 10)
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 60, height: 14)
                            }
                            .padding(16)
                        )
                        .shimmering()
                }
            } else {
                ForEach(Plan.allCases) { plan in
                    planRow(plan)
                }
            }
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        let isPurchased = storeManager.purchasedProductID?.hasSuffix(plan.rawValue) == true
        let isSelected = selectedPlan == plan
        let isBestValue = plan == .yearly && !isPurchased

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected || isPurchased ? pinkRed : Color.gray.opacity(0.35), lineWidth: 1.5)
                        .background(Circle().fill(isSelected || isPurchased ? AnyShapeStyle(pinkGradient) : AnyShapeStyle(Color.clear)))
                        .frame(width: 22, height: 22)

                    if isSelected || isPurchased {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(inkPrimary)

                        if isPurchased {
                            Text("Current Plan")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green))
                        } else if isBestValue {
                            Text("Best Value")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(pinkGradient))
                        } else if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(pinkGradient))
                        }
                    }
                    Text(plan.subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(inkSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    let displayPrice = storeManager.products.first(where: { $0.id.hasSuffix(plan.rawValue) }).map { $0.displayPrice + plan.suffix } ?? plan.fallbackPrice

                    Text(displayPrice)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(inkPrimary)
                        
                    if plan == .monthly || plan == .yearly {
                        Text("3 Days Free")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 0.15, green: 0.68, blue: 0.38))) // Vibrant green
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected || isPurchased ? pinkRed.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
            )
            // Elevated card for yearly (best value)
            .scaleEffect(isBestValue && isSelected ? 1.02 : 1.0)
            .shadow(
                color: isBestValue && isSelected ? pinkRed.opacity(0.15) : Color.clear,
                radius: 8, x: 0, y: 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manage Subscription

    private var manageSubscriptionLink: some View {
        Button(action: {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "gear")
                    .font(.system(size: 15, weight: .medium))
                Text("Manage Subscription")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }
            .foregroundColor(pinkRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardSurface)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sticky CTA footer

    private var ctaFooter: some View {
        let isSelectedPlanPurchased = storeManager.purchasedProductID?.hasSuffix(selectedPlan.rawValue) == true
        
        return VStack(spacing: 10) {
            Button(action: {
                Task {
                    AnalyticsManager.shared.logPremiumPurchaseStarted()
                    isPurchasing = true
                    defer { isPurchasing = false }
                    
                    if let product = storeManager.products.first(where: { $0.id.hasSuffix(selectedPlan.rawValue) }) {
                        do {
                            try await storeManager.purchase(product)
                            if storeManager.isPremium {
                                AnalyticsManager.shared.logPremiumPurchaseSuccess()
                                dismiss()
                            } else {
                                // User cancelled the purchase dialog
                                AnalyticsManager.shared.logPremiumPurchaseCancelled()
                            }
                        } catch {
                            AnalyticsManager.shared.logPremiumPurchaseFailed(error: error.localizedDescription)
                            purchaseErrorMessage = "Something went wrong. Please try again.\n\n\(error.localizedDescription)"
                            showPurchaseError = true
                        }
                    } else {
                        purchaseErrorMessage = "Unable to load products. Please check your internet connection and try again."
                        showPurchaseError = true
                    }
                }
            }) {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(isSelectedPlanPurchased ? "Current Plan" : (selectedPlan == .weekly ? "Continue" : "Start 3-Day Free Trial"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelectedPlanPurchased ? AnyShapeStyle(Color.gray.opacity(0.8)) : AnyShapeStyle(pinkGradient))
                .clipShape(Capsule())
                .shadow(color: isSelectedPlanPurchased ? .clear : pinkRed.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .disabled(isPurchasing || isSelectedPlanPurchased)

            HStack(spacing: 12) {
                Button("Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                        if storeManager.isPremium {
                            AnalyticsManager.shared.logPremiumRestoreSuccess()
                            dismiss()
                        } else {
                            AnalyticsManager.shared.logPremiumRestoreFailed()
                        }
                    }
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(pinkRed)
                
                Text("•")
                    .foregroundColor(inkSecondary)
                
                // Tappable Terms & Privacy links (required by Apple)
                Link("Terms", destination: URL(string: "https://sites.google.com/view/dailyplanner-terms")!)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
                
                Text("&")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(inkSecondary)
                
                Link("Privacy", destination: URL(string: "https://habitplanner.blogspot.com/2026/08/privacy-policy.html")!)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(inkSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .background(
            LinearGradient(
                colors: [Color.pageSurface.opacity(0), Color.pageSurface],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 130)
            .allowsHitTesting(false),
            alignment: .top
        )
    }
}

// MARK: - Shimmer Effect for Loading State

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.3 + phase * geo.size.width * 1.6)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    PremiumUpgradeView()
        .environmentObject(AppThemeManager())
        .environmentObject(StoreManager())
}
