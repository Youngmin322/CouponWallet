////
////  Extensions.swift
////  CouponWallet
////
////  Created by 조영민 on 3/7/25.
////
//
//import SwiftUI
//
//
//// 기프티콘 카드
//struct GifticonCard: View {
//    let gifticon: Gifticon
//    let isExpired: Bool
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            ZStack(alignment: .topTrailing) {
//                // 이미지 로드 방식
//                if !gifticon.imagePath.isEmpty {
//                    // 저장된 이미지 경로가 있으면 해당 이미지 로드
//                    AsyncImage(url: URL(string: gifticon.imagePath)) { image in
//                        image
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                    } placeholder: {
//                        Color.gray.opacity(0.1)
//                    }
//                    .frame(height: 100)
//                } else {
//                    // 이미지가 없을 경우 플레이스홀더 표시
//                    Rectangle()
//                        .fill(Color.gray.opacity(0.1))
//                        .frame(height: 100)
//                        .overlay(
//                            Text(gifticon.brand)
//                                .foregroundColor(.gray)
//                        )
//                }
//                
//                if gifticon.isUsed {
//                    Text("사용완료")
//                        .font(.caption)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color.blue.opacity(0.7))
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .padding(8)
//                } else if gifticon.expirationDate <= Date() {
//                    Text("만료")
//                        .font(.caption)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color.gray.opacity(0.7))
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .padding(8)
//                }
//            }
//            
//            Text(gifticon.brand)
//                .font(.caption)
//                .foregroundColor(.gray)
//            
//            Text(gifticon.productName)
//                .font(.headline)
//                .lineLimit(1)
//            
//            Text("\(gifticon.formattedExpiryDate) 까지")
//                .font(.caption)
//                .foregroundColor(.gray)
//        }
//        .padding(12)
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//        .opacity(isExpired ? 0.7 : 1.0)
//    }
//}
//
// 뷰를 이미지로 변환하는 UIView 확장

import SwiftUI

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

