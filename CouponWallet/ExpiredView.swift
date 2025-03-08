//
//  ExpiredView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import SwiftData

struct ExpiredView: View {
    @State private var selectedFilter = "전체"
    let filters = ["전체", "스타벅스", "치킨", "CU", "GS25", "다이소"]
    
    @Query private var expiredGifticons: [Gifticon]
    
    init() {
        let now = Date()
        // 사용되었거나 만료된 기프티콘
        let predicate = #Predicate<Gifticon> { gifticon in
            gifticon.isUsed || gifticon.expirationDate <= now
        }
        _expiredGifticons = Query(filter: predicate, sort: [SortDescriptor(\.expirationDate, order: .reverse)])
    }
    
    // 필터링된 쿠폰 목록
    var filteredGifticons: [Gifticon] {
        if selectedFilter == "전체" {
            return expiredGifticons
        } else {
            return expiredGifticons.filter { $0.brand == selectedFilter }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 필터 옵션
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filters, id: \.self) { filter in
                            FilterButton(title: filter, isSelected: filter == selectedFilter) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                // 기프티콘 그리드
                if filteredGifticons.isEmpty {
                    Spacer()
                    Text("표시할 만료된 쿠폰이 없습니다")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredGifticons) { gifticon in
                                GifticonCard(gifticon: gifticon, isExpired: true)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("사용·만료")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 필터 버튼
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.black : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

// 기프티콘 카드
struct GifticonCard: View {
    let gifticon: Gifticon
    let isExpired: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // 이미지 로드 방식
                if !gifticon.imagePath.isEmpty {
                    // 저장된 이미지 경로가 있으면 해당 이미지 로드
                    AsyncImage(url: URL(string: gifticon.imagePath)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(height: 100)
                } else {
                    // 이미지가 없을 경우 플레이스홀더 표시
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 100)
                        .overlay(
                            Text(gifticon.brand)
                                .foregroundColor(.gray)
                        )
                }
                
                if gifticon.isUsed {
                    Text("사용완료")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(8)
                } else if gifticon.expirationDate <= Date() {
                    Text("만료")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(8)
                }
            }
            
            Text(gifticon.brand)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(gifticon.productName)
                .font(.headline)
                .lineLimit(1)
            
            
            
            Text("\(gifticon.formattedExpiryDate) 까지")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(isExpired ? 0.7 : 1.0)
    }
}

extension Int {
    var formattedWithComma: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

#Preview {
    ExpiredView()
        .modelContainer(for: Gifticon.self, inMemory: true)
}
