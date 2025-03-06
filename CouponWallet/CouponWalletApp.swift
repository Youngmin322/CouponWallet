//
//  CouponWalletApp.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import SwiftData

@main
struct CouponWalletApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Gifticon.self)
        }
    }
}
