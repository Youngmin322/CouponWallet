//
//  SelectedCouponView.swift
//  CouponWallet
//
//  Created by Sean on 3/6/25.
//

import SwiftUI
import SwiftData

struct SelectedCouponView: View {
    let selectedGifticons = Gifticon.coupons
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(0..<selectedGifticons.count, id: \.self) { index in
                SelectedCouponCell(selectedCoupon: selectedGifticons[index])
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // 페이지 스타일 적용
        .animation(.easeInOut, value: selectedIndex) // 부드러운 애니메이션 효과
        
        HStack {
            Spacer()
            Button("사용하지 않기") {
                // 홈 화면으로 돌아가기
                AvailableGifticonView()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            Spacer()
            
            Button("사용하기") {
                selectedGifticons[selectedIndex].isUsed = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            Spacer()
        }
        .padding()
    }
}
            

struct SelectedCouponCell: View {
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
                Text("쿠폰 사용기간 만료일: ~ \(selectedCoupon.formattedExpiryDate) 까지")
                    .font(.body)
                HStack {
                    Image(systemName: selectedCoupon.isUsed ? "xmark.circle.fill" : "checkmark.circle.fill")
                    Text(selectedCoupon.isUsed ? "사용 불가" : "사용 가능")
                        .font(.body)
                }
            }
        }
    }
}

#Preview {
    SelectedCouponView()
}
