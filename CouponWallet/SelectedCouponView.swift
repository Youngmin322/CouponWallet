//
//  SelectedCouponView.swift
//  CouponWallet
//
//  Created by Sean on 3/6/25.
//

import SwiftUI
import SwiftData

struct SelectedCouponView: View {
    let selectedCoupons = Gifticon.coupons
    @State private var selectedIndex: Int = 0
    @State private var deletedGifticons: [Gifticon] = [] // 삭제된 기프티콘 배열 추가
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $selectedIndex) {
                    ForEach(0..<selectedCoupons.count, id: \.self) { index in
                        SelectedCouponCell(selectedCoupon: selectedCoupons[index])
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)) // 페이지 스타일 적용
                .animation(.easeInOut, value: selectedIndex) // 부드러운 애니메이션 효과
                
                HStack {
                    Spacer()
                    NavigationLink(destination: AvailableGifticonView()) {
                        Text("사용하지 않기")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    Spacer()
                    
                    NavigationLink(destination: ExpiredView(deletedGifticons: $deletedGifticons)) {
                        Button("사용하기", action: {
                            selectedCoupons[selectedIndex].isUsed = true
                        })
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        Spacer()
                    }
                }
                .padding()
            }
        }
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
    SelectedCouponView()
}

//                    NavigationLink(destination: selectedCoupons[selectedIndex].isUsed ? ExpiredView() : AvailableGifticonView())
