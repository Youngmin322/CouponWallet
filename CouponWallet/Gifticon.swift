//
//  Gifticon.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftData
import Foundation

@Model
class Gifticon {
    var id: UUID
    var brand: String
    var expirationDate: Date
    var productName: String
    var imagePath: String
    var isUsed: Bool
    
    init(brand: String, productName: String, expirationDate: Date, isUsed: Bool, imagePath: String) {
        self.id = UUID()
        self.brand = brand
        self.productName = productName
        self.expirationDate = expirationDate
        self.isUsed = isUsed
        self.imagePath = imagePath
    }
    
    var formattedExpiryDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: expirationDate)
    }
}

