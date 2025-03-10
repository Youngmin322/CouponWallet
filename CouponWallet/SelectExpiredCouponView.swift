//
//  SelectExpiredCouponView.swift
//  CouponWallet
//
//  Created by Sean on 3/6/25.
//

import SwiftUI
import SwiftData

struct SelectExpiredCouponView: View {
    // Use a Query to fetch expired gifticons
    @Query private var expiredGifticons: [Gifticon]
    @State private var selectedIndex: Int = 0
    @State private var deletedGifticons: [Gifticon] = [] // 삭제된 기프티콘 배열 추가
    
    init() {
        let now = Date()
        // 쿼리: 만료되었거나 사용된 기프티콘 필터링
        let predicate = #Predicate<Gifticon> { gifticon in
            gifticon.isUsed || gifticon.expirationDate <= now
        }
        _expiredGifticons = Query(filter: predicate, sort: [SortDescriptor(\.expirationDate)])
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if expiredGifticons.isEmpty {
                    Text("표시할 만료된 쿠폰이 없습니다")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    TabView(selection: $selectedIndex) {
                        ForEach(0..<expiredGifticons.count, id: \.self) { index in
                            SelectExpiredCouponCell(selectedCoupon: expiredGifticons[index])
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // 페이지 스타일 적용
                    .animation(.easeInOut, value: selectedIndex) // 부드러운 애니메이션 효과
                }
            }
            .navigationTitle("만료된 쿠폰")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { value in
                if value == "Expired" {
                    ExpiredView(deletedGifticons: $deletedGifticons)
                }
            }
        }
    }
}
            
struct SelectExpiredCouponCell: View {
    var selectedCoupon: Gifticon
    
    var body: some View {
        Form {
            Section(header: Text("선택 쿠폰")) {
                if !selectedCoupon.imagePath.isEmpty {
                    AsyncImage(url: URL(string: selectedCoupon.imagePath)) { image in
                        image
                            .resizable()
                            .clipShape(.rect(cornerRadius: 12))
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                Text(selectedCoupon.brand)
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Image(systemName: "gift")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .padding()
                }
                
                Text(selectedCoupon.productName)
                    .font(.headline)
                Text(selectedCoupon.brand)
                    .font(.body)
                Text("쿠폰 만료일: ~ \(selectedCoupon.formattedExpiryDate) 까지")
                    .font(.body)
                HStack {
                    Image(systemName: selectedCoupon.isUsed ? "xmark.circle.fill" : "checkmark.circle")
                    Text(selectedCoupon.isUsed ? "사용 불가" : "사용 가능")
                        .font(.body)
                }
            }
        }
    }
}

#Preview {
    SelectExpiredCouponView()
        .modelContainer(for: Gifticon.self, inMemory: true)
}
