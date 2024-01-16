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
  
    var body: some View {
      SubscriptionStoreView(groupID: "21431347", visibleRelationships: .all) {
        StoreContent()
          .containerBackground(Color.cyan.gradient, for: .subscriptionStoreHeader)
      }
      .backgroundStyle(.clear)
      .subscriptionStorePickerItemBackground(.thinMaterial)
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
}

#Preview {
    ContentView()
}
