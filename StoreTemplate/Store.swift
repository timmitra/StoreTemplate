//
//  Store.swift
//  StoreTemplate
//
//  Created by Tim Mitra on 2024-01-16.
//

import Foundation
import StoreKit

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreError: Error {
  case failedVerification
}

public enum SubscriptionTier: Int, Comparable {
  case none = 0
  case monthly = 1
  case yearly = 2
  
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}

class Store: ObservableObject {
  @Published private(set) var lifetime: [Product]
  @Published private(set) var subscriptions: [Product]
  @Published private(set) var purchasedSubscriptions: [Product] = []
  @Published private(set) var purchasedLifetime: Bool = false
  @Published private(set) var subscriptionGroupStatus: RenewalState?
  
  var updateListenerTask: Task<Void, Error>? = nil
  private let productIds: [String: String]
  
  init() {
    productIds = Store.loadProductIdData()
    
    subscriptions = []
    lifetime = []
    
    Task {
      await requestProducts()
      
      await updateCustomerProductStatus()
    }
  }
  deinit {
    updateListenerTask?.cancel()
  }
  
  static func loadProductIdData() -> [String: String] {
    guard let path = Bundle.main.path(forResource: "SampleStore", ofType: "plist"),
          let plist = FileManager.default.contents(atPath: path),
          let data = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String] else { return [:] }
    return data
  }
  
  func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
      for await result in Transaction.updates {
        do {
          let transaction = try self.checkVerified(result)
          await self.updateCustomerProductStatus()
          await transaction.finish()
        } catch {
          print("transaction failed verification")
        }
      }
    }
  }
  
  func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return safe
    }
  }
  
  @MainActor
  func updateCustomerProductStatus() async {
    var purchasedSubscriptions: [Product] = []
    
    for await result in Transaction.currentEntitlements {
      do {
        let transaction = try checkVerified(result)
        
        switch transaction.productType {
        case .nonConsumable:
          purchasedLifetime = true
        case .autoRenewable:
          if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
            purchasedSubscriptions.append(subscription)
          }
        default:
          break
        }
      } catch {
        print("could not find products")
      }
    }
    self.purchasedSubscriptions = purchasedSubscriptions
    self.purchasedLifetime = purchasedLifetime
    
    subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
  }
  
  @MainActor
  func requestProducts() async {
    do {
      let storeProducts = try await Product.products(for: productIds.keys)
      var newLifetime: [Product] = []
      var newSubscriptions: [Product] = []
      
      for product in storeProducts {
        switch product.type {
        case .nonConsumable:
          newLifetime.append(product)
        case .autoRenewable:
          newSubscriptions.append(product)
        default:
          print("unknown product")
        }
      }
      lifetime = sortByPrice(newLifetime)
      subscriptions = sortByPrice(newSubscriptions)
    } catch {
      print("failed to get products from Apple Servers: \(error)")
    }
  }
  
  func sortByPrice(_ products: [Product]) -> [Product] {
    products.sorted(by: { return $0.price < $1.price })
  }
  
  func tier(for productId: String) -> SubscriptionTier {
    switch productId {
    case "monthy_subscription":
      return .monthly
    case "yearly_subscription":
      return .yearly
    default:
      return .none
    }
  }
  
  func isPurchased(_ product: Product) async throws -> Bool {
    switch product.type {
    case .nonConsumable:
      return purchasedLifetime
    case .autoRenewable:
      return purchasedSubscriptions.contains(product)
    default:
      return false
    }
  }
  
  func purchase(_ product: Product) async throws -> Transaction? {
    let result = try await product.purchase()
    switch result {
    case .success(let verification):
      let transaction = try checkVerified(verification)
      await updateCustomerProductStatus()
      await transaction.finish()
      return transaction
    case .userCancelled, .pending:
      return nil
    default: return nil
    }
  }
}
