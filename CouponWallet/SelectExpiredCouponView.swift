//
//  SelectedCouponView.swift
//  CouponWallet
//
//  Created by Sean on 3/6/25.
//

import SwiftUI
import SwiftData

struct SelectExpiredCouponView: View {
    let selectedCoupons = Gifticon.coupons
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(0..<selectedCoupons.count, id: \.self) { index in
                    SelectExpiredCouponCell(selectedCoupon: selectedCoupons[index])
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // 페이지 스타일 적용
            .animation(.easeInOut, value: selectedIndex) // 부드러운 애니메이션 효과
            .navigationDestination(for: String.self) { value in
                if value == "Expired" {
                    ExpiredView()
                }
            }
//            .navigationLink(destination: ExpiredView())
        }
    }
}
            

struct SelectExpiredCouponCell: View {
    var selectedCoupon: Gifticon
    
    var body: some View {
        Form {
            Section(header: Text("선택 쿠폰")) {
                Image(systemName: selectedCoupon.imagePath)
                    .resizable()
                    .clipShape(.rect(cornerRadius: 12))
                    .aspectRatio(contentMode: .fit)
                    .padding()
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
}

//                    NavigationLink(destination: selectedCoupons[selectedIndex].isUsed ? ExpiredView() : AvailableGifticonView())
