//
//  ExpiredView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import SwiftData

struct ExpiredView: View {
    @State private var showDeleteAlert: Bool = false
    @State private var selectedFilter = "전체"
    @State private var isCheckMode: Bool = false
    @State private var selectedGifticon: Gifticon?
    // 더미 데이터
    @State private var expiredGifticons: [Gifticon] = Gifticon.dummyData
    
    let filters = ["전체", "스타벅스", "치킨", "CU", "GS25", "다이소"]
    
    // 필터링된 쿠폰 목록
    var filteredGifticons: [Gifticon] {
        if selectedFilter == "전체" {
            return expiredGifticons
        } else {
            return expiredGifticons.filter { $0.brand == selectedFilter }
        }
    }
    /* swiftData 사용할때
    @Query private var expiredGifticons: [Gifticon]
        
        init() {
            let now = Date()
            // 사용되었거나 만료된 기프티콘
            let predicate = #Predicate<Gifticon> { gifticon in
                gifticon.isUsed || gifticon.expirationDate <= now
            }
            _expiredGifticons = Query(filter: predicate, sort: [SortDescriptor(\.expirationDate, order: .reverse)])
        }
    */
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
                                ZStack {
                                    // 원래 기프티콘 카드
                                    GifticonCard(gifticon: gifticon, isExpired: true)
                                    
                                    // 체크 모드일 때 중앙에 체크 아이콘 표시
                                    if isCheckMode {
                                        Button {
                                            selectedGifticon = gifticon
                                            showDeleteAlert = true
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white).opacity(0.8))
                                                .clipShape(Circle())
                                        }
                                        .position(x: 90, y: 60) // 중앙 정렬 (기프티콘 이미지 크기에 맞춰 조정)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("사용·만료")
            .navigationBarTitleDisplayMode(.inline)
            // 체크 모드 활성 - 비활성화
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCheckMode.toggle()
                    } label: {
                        Image(systemName: isCheckMode ? "xmark.circle" : "trash")
                            .foregroundColor(.red)
                    }
                }
            }
           
            .alert("이 기프티콘을 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    if let selected = selectedGifticon {
                        expiredGifticons.removeAll { $0.id == selected.id }
                        print("\(selected.productName) 삭제됨")
                    }
                    showDeleteAlert = false
                }
                Button("취소", role: .cancel) {
                    showDeleteAlert = false
                }
            } message: {
                Text("해당 쿠폰은 휴지통으로 이동됩니다")
            }
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
            ZStack {
                if !gifticon.imagePath.isEmpty {
                    AsyncImage(url: URL(string: gifticon.imagePath)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(height: 100)
                } else {
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
                        .position(x: 140, y: 10)
                } else if gifticon.expirationDate <= Date() {
                    Text("만료")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(8)
                        .position(x: 140, y: 10)
                }
            }

            Text(gifticon.brand)
                .font(.caption)
                .foregroundColor(.gray)

            Text(gifticon.productName)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Text("\(gifticon.price.formattedWithComma)원")
                    .fontWeight(.bold)

                Text("\(gifticon.discount)%")
                    .foregroundColor(.red)
                    .font(.caption)
                    .fontWeight(.bold)
            }

            Text("\(gifticon.originalPrice.formattedWithComma)원")
                .font(.caption)
                .foregroundColor(.gray)
                .strikethrough()

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
}
