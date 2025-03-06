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
    var price: Int
    var originalPrice: Int
    
    init(brand: String, productName: String, expirationDate: Date, isUsed: Bool, imagePath: String, price: Int, originalPrice: Int) {
        self.id = UUID()
        self.brand = brand
        self.productName = productName
        self.expirationDate = expirationDate
        self.isUsed = isUsed
        self.imagePath = imagePath
        self.price = price
        self.originalPrice = originalPrice
    }
    
    var discount: Int {
        guard originalPrice > 0 else { return 0 }
        return Int(Double(originalPrice - price) / Double(originalPrice) * 100)
    }
    
    var formattedExpiryDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: expirationDate)
    }
}
// Gifticon 더미 데이터
extension Gifticon {
    static let dummyData: [Gifticon] = [
        Gifticon(brand: "스타벅스", productName: "카페아메리카노 T", expirationDate: Date().addingTimeInterval(-86400), isUsed: false, imagePath: "", price: 4150, originalPrice: 4700),
        Gifticon(brand: "스타벅스", productName: "카페아메리카노 T", expirationDate: Date().addingTimeInterval(-604800), isUsed: false, imagePath: "", price: 4050, originalPrice: 4700),
        Gifticon(brand: "GS25", productName: "빙그레 바나나우유", expirationDate: Date().addingTimeInterval(-259200), isUsed: true, imagePath: "", price: 1200, originalPrice: 1800),
        Gifticon(brand: "스타벅스", productName: "카페아메리카노 T", expirationDate: Date().addingTimeInterval(-86400), isUsed: false, imagePath: "", price: 4150, originalPrice: 4700),
        Gifticon(brand: "스타벅스", productName: "카페아메리카노 T", expirationDate: Date().addingTimeInterval(-604800), isUsed: false, imagePath: "", price: 4050, originalPrice: 4700),
        Gifticon(brand: "GS25", productName: "빙그레 바나나우유", expirationDate: Date().addingTimeInterval(-259200), isUsed: true, imagePath: "", price: 1200, originalPrice: 1800)
    ]
}
