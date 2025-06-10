import Foundation
import OSLog
import StoreKit

enum TrialStatus: Equatable{
  case loading
  case active(daysLeft: Int)
  case expired
  case purchased // user bought app
}

@MainActor
final class StoreManager: ObservableObject {
  @Published var products: [Product] = []
  @Published var purchasedProductIDs: Set<String> = []
  @Published var isLoading = false
  @Published var purchaseError: String?
  
  // trial stuff
  @Published var trialStatus: TrialStatus = .loading
  @Published var daysRemaining: Int = 0
  @Published var hoursRemaining: Int = 0
  private let trialDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
  
  static let shared = StoreManager()
  private let licenseProductID = "com.marceloexc.rm2000.lifetime"

  var hasPurchasedApp: Bool {
    purchasedProductIDs.contains(licenseProductID)
  }
  
  var hasAccess: Bool {
    switch trialStatus {
    case .active, .purchased:
      return true
    case .expired, .loading:
      return false
    }
  }
  
  var isPurchased: Bool {
    if case .purchased = trialStatus {
      return true
    }
    return false
  }
  
  var isTrialActive: Bool {
    if case .active = trialStatus {
      return true
    }
    return false
  }
  
  var isTrialExpired: Bool {
    if case .expired = trialStatus {
      return true
    }
    return false
  }
  
  var timeRemainingString: String {
    switch trialStatus {
    case .active(let daysLeft):
      if daysLeft > 1 {
        return "\(daysLeft) days remaining"
      } else if daysLeft == 1 {
        return "1 day remaining"
      } else {
        return "\(hoursRemaining) hours remaining"
      }
    case .expired:
      return "Trial expired"
    case .purchased:
      return "Lifetime access"
    case .loading:
      return "Loading..."
    }
  }

  private var transactionListener: Task<Void, Error>?

  private init() {
    transactionListener = listenForTransactions()

    Task {
      await loadProductsFromAppStore()
      await updatePurchasedProducts()
      updateTrialStatus()
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
        purchaseCompleted()
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
  
  func updateTrialStatus() {
    // Check if user has purchased lifetime access first
    if hasPurchasedApp { 
      trialStatus = .purchased
      return
    }
    
    let installDate = getInstallDate()
    let now = Date()
    let timeElapsed = now.timeIntervalSince(installDate)
    
    if timeElapsed < trialDuration {
      // Trial is still active
      let timeRemaining = trialDuration - timeElapsed
      let daysLeft = Int(ceil(timeRemaining / (24 * 60 * 60)))
      let hoursLeft = Int(ceil(timeRemaining / (60 * 60))) % 24
      
      self.daysRemaining = max(0, daysLeft)
      self.hoursRemaining = hoursLeft
      self.trialStatus = .active(daysLeft: daysLeft)
      
      Logger.store.info("Trial active: \(daysLeft) days remaining")
    } else {
      // Trial has expired
      self.daysRemaining = 0
      self.hoursRemaining = 0
      self.trialStatus = .expired
      
      Logger.store.info("Trial expired")
    }
  }
  
  private func getInstallDate() -> Date {
    let key = "app_first_launch_date"
    
    // Check if we already have an install date
    if let existingDate = UserDefaults.standard.object(forKey: key) as? Date {
      return existingDate
    }
    
    // This is the first launch, record the install date
    let installDate = Date()
    UserDefaults.standard.set(installDate, forKey: key)
    
    Logger.store.info("First app launch recorded: \(installDate)")
    return installDate
  }
  
  // Call this when the user purchases lifetime access
  func purchaseCompleted() {
    trialStatus = .purchased
    Logger.store.info("Switched trial to .purchased")
  }
}

enum StoreError: Error {
  case failedVerification
}

extension Logger {
  static let store = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "App", category: "Store")
}
