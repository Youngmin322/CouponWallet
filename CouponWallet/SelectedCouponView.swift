//
//  SelectedCouponView.swift
//  CouponWallet
//
//  Created by Sean on 3/6/25.
//

import SwiftUI
import SwiftData

struct SelectedCouponView: View {
    // Replace static access with a parameter
    @Query private var availableGifticons: [Gifticon]
    @State private var selectedIndex: Int = 0
    @State private var deletedGifticons: [Gifticon] = [] // 삭제된 기프티콘 배열 추가
    
    init() {
        let now = Date()
        // 사용 가능한 기프티콘: 만료되지 않았고 사용되지 않은 것
        let predicate = #Predicate<Gifticon> { gifticon in
            !gifticon.isUsed && gifticon.expirationDate > now
        }
        _availableGifticons = Query(filter: predicate, sort: [SortDescriptor(\.expirationDate)])
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if availableGifticons.isEmpty {
                    Text("표시할 쿠폰이 없습니다")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    TabView(selection: $selectedIndex) {
                        ForEach(0..<availableGifticons.count, id: \.self) { index in
                            SelectedCouponCell(selectedCoupon: availableGifticons[index])
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
                        
                        Button("사용하기") {
                            if !availableGifticons.isEmpty {
                                // Make sure we have a valid index
                                let safeIndex = min(selectedIndex, availableGifticons.count - 1)
                                if safeIndex >= 0 {
                                    // Mark the gifticon as used
                                    availableGifticons[safeIndex].isUsed = true
                                }
                            }
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
        }
    }
}

struct SelectedCouponCell: View {
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
    SelectedCouponView()
        .modelContainer(for: Gifticon.self, inMemory: true)
}
