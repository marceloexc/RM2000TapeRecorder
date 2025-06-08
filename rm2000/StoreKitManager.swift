import Foundation
import OSLog
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
  @Published var products: [Product] = []
  @Published var purchasedProductIDs: Set<String> = []
  @Published var isLoading = false
  @Published var purchaseError: String?

  static let shared = StoreManager()
  private let licenseProductID = "com.marceloexc.rm2000.lifetime"

  var hasPurchasedApp: Bool {
    purchasedProductIDs.contains(licenseProductID)
  }

  private var transactionListener: Task<Void, Error>?

  private init() {
    transactionListener = listenForTransactions()

    Task {
      await loadProductsFromAppStore()
      await updatePurchasedProducts()
    }
  }

  deinit {
    transactionListener?.cancel()
  }

  func loadProductsFromAppStore() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let products = try await Product.products(for: [licenseProductID])
      self.products = products
      Logger.store.info("Loaded \(products.count) products")
    } catch {
      Logger.store.error("Failed to load products: \(error)")
      purchaseError = "Failed to load products: \(error.localizedDescription)"
    }
  }

  func purchaseAppLicenseThankYouSoMuch() async {
    guard let product = products.first(where: { $0.id == licenseProductID })
    else {
      purchaseError = "Product not found"
      return
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let result = try await product.purchase()

      switch result {
      case .success(let verification):
        let transaction = try checkVerified(verification)
        await transaction.finish()
        await updatePurchasedProducts()
        Logger.store.info("Successfully purchased lifetime access")

      case .userCancelled:
        Logger.store.info("User cancelled purchase")

      case .pending:
        Logger.store.info("Purchase is pending")
        purchaseError = "Purchase is pending approval"

      @unknown default:
        Logger.store.error("Unknown purchase result")
        purchaseError = "Unknown error occurred"
      }
    } catch {
      Logger.store.error("Purchase failed: \(error)")
      purchaseError = "Purchase failed: \(error.localizedDescription)"
    }
  }

  func restorePurchases() async {
    isLoading = true
    defer { isLoading = false }

    do {
      try await AppStore.sync()
      await updatePurchasedProducts()
      Logger.store.info("Successfully restored purchases")
    } catch {
      Logger.store.error("Failed to restore purchases: \(error)")
      purchaseError =
        "Failed to restore purchases: \(error.localizedDescription)"
    }
  }

  private func updatePurchasedProducts() async {
    var purchasedIDs: Set<String> = []

    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try checkVerified(result)
        if transaction.revocationDate == nil {
          purchasedIDs.insert(transaction.productID)
        }
      } catch {
        Logger.store.error("Failed to verify transaction: \(error)")
      }
    }

    self.purchasedProductIDs = purchasedIDs
    Logger.store.info("Updated purchased products: \(purchasedIDs)")
  }

  private func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
      for await result in Transaction.updates {
        do {
          let transaction = try await self.checkVerified(result)
          await transaction.finish()
          await self.updatePurchasedProducts()
        } catch {
          Logger.store.error("Transaction verification failed: \(error)")
        }
      }
    }
  }

  private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return safe
    }
  }
}

enum StoreError: Error {
  case failedVerification
}

extension Logger {
  static let store = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "App", category: "Store")
}
