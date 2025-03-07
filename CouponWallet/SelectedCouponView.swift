//
//  SelectedCouponView.swift
//  CouponWallet
//
//  Created by Sean on 3/6/25.
//

import SwiftUI
import SwiftData

//struct SelectedCouponView: View {
//    let selectedGifticons: [Gifticon]
//    @State var selectedIndex: Int
//    @Binding @State var isUsed: Bool
//    
//    var body: some View {
//        VStack {
//            SelectedCouponCell(selectedCoupon: coupons)
//            ZStack {
//                Image(selectedGifticons[selectedIndex].productName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 300, height: 300)
//                    .overlay(
//                        selectedGifticons[selectedIndex].isUsed ?
//                        Color.gray.opacity(0.5) : Color.clear // 사용된 쿠폰에 회색 필터 적용
//                    )
//                
//                // 스와이프 제스처 감지
//                HStack {
//                    if selectedIndex > 0 {
//                        Button(action: {
//                            selectedIndex -= 1
//                        }) {
//                            Image(systemName: "chevron.left")
//                                .font(.largeTitle)
//                                .padding()
//                        }
//                    }
//
//                    Spacer()
//                    
//                    if selectedIndex < selectedGifticons.count - 1 {
//                        Button(action: {
//                            selectedIndex += 1
//                        }) {
//                            Image(systemName: "chevron.right")
//                                .font(.largeTitle)
//                                .padding()
//                        }
//                    }
//                }
//            }
//            .gesture(DragGesture().onEnded { value in
//                if value.translation.width < -50 && selectedIndex < selectedGifticons.count - 1 {
//                    selectedIndex += 1 // 오른쪽으로 스와이프하면 다음 쿠폰
//                } else if value.translation.width > 50 && selectedIndex > 0 {
//                    selectedIndex -= 1 // 왼쪽으로 스와이프하면 이전 쿠폰
//                }
//            })
//            .padding()
            
//            HStack {
//                Spacer()
//                Button("사용하지 않기") {
//                    // 홈 화면으로 돌아가기
//                    selectedIndex = -1
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(10)
//                Spacer()
//                Button("사용하기") {
//                    selectedGifticons[selectedIndex].isUsed = true
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.red)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                Spacer()
//            }
//            .padding()
//        }
//        .navigationBarBackButtonHidden(true)
//    }
//}

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
                    Text("사용 여부")
                        .font(.body)
                    Spacer()
                    Image(systemName: selectedCoupon.isUsed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    
                }
            }
        }
    }
}

//#Preview {
//    SelectedCouponView(selectedCoupons: coupons[0], selectedIndex: 0, isExpired: false)
//
////    SelectedCouponView()
////        .modelContainer(for: Gifticon.self, inMemory: true)
//}

#Preview {
    SelectedCouponCell(selectedCoupon: Gifticon.coupons[1])
}
