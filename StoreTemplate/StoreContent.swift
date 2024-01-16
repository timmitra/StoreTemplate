//
//  StoreContent.swift
//  RevenueCatDemo
//
//  Created by Tim Mitra on 1/8/24.
//

import SwiftUI

struct StoreContent: View {
  @AppStorage("subscribed") private var subscribed: Bool = false
  
    var body: some View {
      ZStack {
        VStack {
          Text(subscribed ? "Thanks" : "Choose a plan")
            .font(.largeTitle.bold())
          Image(.store)
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
            .frame(width: 100)
            .padding()
          }
      }
    }
}

#Preview {
    StoreContent()
}
