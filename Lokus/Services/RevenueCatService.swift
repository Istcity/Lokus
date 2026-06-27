// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation
import RevenueCat

/// RevenueCat premium abonelik yönetimi.
@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()

    @Published private(set) var isPremium = false
    @Published private(set) var isLoading = false
    @Published private(set) var premiumPriceText: String?
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isConfigured = false

    private var purchasesDelegateInstalled = false

    private init() {}

    /// RevenueCat SDK yapılandırmasını başlatır.
    func configure() {
        guard AppConfiguration.isRevenueCatConfigured else {
            isConfigured = false
            return
        }

        if !purchasesDelegateInstalled {
            Purchases.logLevel = .error
            Purchases.configure(withAPIKey: AppConfiguration.revenueCatAPIKey)
            Purchases.shared.delegate = PurchasesDelegateHandler.shared
            purchasesDelegateInstalled = true
        }

        isConfigured = true
    }

    /// Premium durumunu ve fiyat bilgisini günceller.
    func checkPremiumStatus() async {
        guard isConfigured else { return }

        isLoading = true
        defer { isLoading = false }

        async let customerTask: Void = refreshCustomerInfo()
        async let offeringsTask: Void = loadOfferings()
        _ = await (customerTask, offeringsTask)
    }

    /// Yıllık premium aboneliği satın alır.
    func purchasePremium() async throws {
        guard isConfigured else { throw LokusError.premiumRequired }

        isLoading = true
        defer { isLoading = false }

        let offerings = try await Purchases.shared.offerings()
        guard let package = premiumPackage(from: offerings) else {
            throw LokusError.premiumRequired
        }

        let result = try await Purchases.shared.purchase(package: package)
        applyCustomerInfo(result.customerInfo)
    }

    /// Önceki satın alımları geri yükler.
    func restorePurchases() async throws {
        guard isConfigured else { throw LokusError.premiumRequired }

        isLoading = true
        defer { isLoading = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        applyCustomerInfo(customerInfo)
    }

    /// RevenueCat'ten gelen müşteri güncellemesini işler.
    func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        let entitlement = customerInfo.entitlements[AppConfiguration.premiumEntitlementID]
        isPremium = entitlement?.isActive == true
        expirationDate = entitlement?.expirationDate
    }

    private func refreshCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            applyCustomerInfo(customerInfo)
        } catch {
            isPremium = false
            expirationDate = nil
        }
    }

    private func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let package = premiumPackage(from: offerings) {
                premiumPriceText = package.storeProduct.localizedPriceString
            }
        } catch {
            premiumPriceText = nil
        }
    }

    private func premiumPackage(from offerings: Offerings) -> Package? {
        offerings.current?.availablePackages.first {
            $0.storeProduct.productIdentifier == AppConfiguration.premiumProductID
        } ?? offerings.current?.annual
    }

    /// Abonelik veya test bypass ile premium erişim.
    var hasPremiumAccess: Bool {
        PremiumAccess.hasPremium(isSubscribed: isPremium)
    }
}

/// RevenueCat müşteri bilgisi delegesi.
private final class PurchasesDelegateHandler: NSObject, PurchasesDelegate {
    static let shared = PurchasesDelegateHandler()

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            RevenueCatService.shared.applyCustomerInfo(customerInfo)
        }
    }
}
