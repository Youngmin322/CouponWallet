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

// Gifticon 더미 데이터
extension Gifticon {
    static let coupons: [Gifticon] = [
        Gifticon(
            brand: "스타벅스",
            productName: "카페 아메리카노 T",
            expirationDate: Date().addingTimeInterval(-86400), // 하루 전 만료
            isUsed: false,
            imagePath: "mug"
        ),
        Gifticon(
            brand: "BHC",
            productName: "뿌링클+콜라 1.25L",
            expirationDate: Date().addingTimeInterval(-604800), // 일주일 전 만료
            isUsed: false,
            imagePath: "mug.fill"
        ),
        Gifticon(
            brand: "GS25",
            productName: "빙그레 바나나우유",
            expirationDate: Date().addingTimeInterval(-259200), // 3일 전 만료
            isUsed: true,
            imagePath: "mug"
        ),
        Gifticon(
            brand: "버거킹",
            productName: "와퍼 세트",
            expirationDate: Date().addingTimeInterval(-172800), // 2일 전 만료
            isUsed: false,
            imagePath: "mug.fill"
        ),
        Gifticon(
            brand: "다이소",
            productName: "다이소 상품권 5,000원",
            expirationDate: Date().addingTimeInterval(-432000), // 5일 전 만료
            isUsed: true,
            imagePath: "mug"
        ),
        Gifticon(
            brand: "배스킨라빈스",
            productName: "쿼터 아이스크림",
            expirationDate: Date().addingTimeInterval(-864000), // 10일 전 만료
            isUsed: false,
            imagePath: "mug.fill"
        ),
    ]
}
