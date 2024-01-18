//
//  ContentView.swift
//  StoreTemplate
//
//  Created by Tim Mitra on 2024-01-16.
//

import SwiftUI
import StoreKit

struct ContentView: View {
  @AppStorage("subscribed") private var subscribed: Bool = false
  @State private var lifetimePage: Bool = false
  @State var purchaseStart: Bool = false
  @StateObject var store: Store = Store()
  
    var body: some View {
      SubscriptionStoreView(groupID: "21431347", visibleRelationships: .all) {
        StoreContent()
          .containerBackground(Color.cyan.gradient, for: .subscriptionStoreHeader)
      }
      .backgroundStyle(.clear)
      .subscriptionStorePickerItemBackground(.thinMaterial)
      .storeButton(.visible, for: .restorePurchases)
      .overlay {
        if purchaseStart {
          ProgressView().controlSize(.extraLarge)
        }
      }
      .onInAppPurchaseStart { product in
        purchaseStart.toggle()
      }
      .onInAppPurchaseCompletion { product, result in
        purchaseStart.toggle()
        Task {
          await store.updateCustomerProductStatus()
          await updateSubscriptionStatus()
        }
      }
      .subscriptionStorePolicyDestination( for: .termsOfService) {
        Text("https://www.it-guy.com")
      }.subscriptionStorePolicyDestination( for: .privacyPolicy) {
        Text("https://www.it-guy.com")
      }
      .sheet(isPresented: $lifetimePage) {
        LifetimeStoreView()
          .presentationDetents([.height(250)])
          .presentationBackground(.ultraThinMaterial)
      }
      Button("More Purchase Options", action: {
        lifetimePage = true
      })
    }
  
  @MainActor
  func updateSubscriptionStatus() async {
    if store.subscriptionGroupStatus == .subscribed || store.subscriptionGroupStatus == .inGracePeriod || store.purchasedLifetime {
      subscribed = true
    } else {
      subscribed = false
    }
  }
}

#Preview {
    ContentView()
}
