//
//  LifetimeStoreView.swift
//  RevenueCatDemo
//
//  Created by Tim Mitra on 1/8/24.
//

import SwiftUI
import StoreKit

struct LifetimeStoreView: View {
  @AppStorage("subscribed") private var subscribed: Bool = false
  
    var body: some View {
      Image(.store)
        .resizable()
        .scaledToFit()
        .clipShape(Circle())
        .frame(width: 100)
        .padding(.top, 20)
      StoreView(ids: ["proplan_rc"])
        .productViewStyle(.large)
    }
}

#Preview {
    LifetimeStoreView()
}
