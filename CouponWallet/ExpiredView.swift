//
//  ExpiredView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import SwiftData

enum GifticonStatus: String, CaseIterable {
    case used = "사용 완료"
    case expired = "만료"
}

struct ExpiredView: View {
    // 날짜 정렬 기준 (true: 최신순, false: 오래된 순)
    @State private var sortByDateDesc: Bool = true
    // 삭제 확인 알림창을 표시할지 여부
    @State private var showDeleteAlert: Bool = false
    // 선택한 상태 필터 (전체 / 사용 완료 / 만료)
    @State private var selectedGifticonStatusFilter: String = "전체"
    // 체크 모드 - 삭제 -> 휴지통이동
    @State private var isCheckMode: Bool = false
    // 선택한 기프티콘
    @State private var selectedGifticon: Gifticon?
    // 만료된 기프티콘 데이터 (더미 데이터 사용)
    @State private var expiredGifticons: [Gifticon] = Gifticon.dummyData
    // 삭제된 기프티콘 목록을 부모 뷰(ContentView)에서 전달받음
    @Binding var deletedGifticons: [Gifticon]

    // 상태 필터 배열 (전체, 사용 완료, 만료)
    let gifticonStatusFilter: [String] = ["전체"] + GifticonStatus.allCases.map { $0.rawValue }
    
    // isUsed 및 expirationDate를 기반으로 상태 결정
    func determineGifticonStatus(_ gifticon: Gifticon) -> String {
        return gifticon.isUsed ? GifticonStatus.used.rawValue : GifticonStatus.expired.rawValue
    }
    
    // 필터 적용 -> 전체, 사용 완료, 만료
    var filteredGifticons: [Gifticon] {
        expiredGifticons.filter { gifticon in
            let status = determineGifticonStatus(gifticon)
            return selectedGifticonStatusFilter == "전체" || status == selectedGifticonStatusFilter
        }
    }

    // 정렬된 기프티콘 목록 반환
    var sortedGifticons: [Gifticon] {
        filteredGifticons.sorted {
            sortByDateDesc ? $0.expirationDate > $1.expirationDate : $0.expirationDate < $1.expirationDate
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 사용 완료 / 만료 필터 옵션만 유지
                //ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(gifticonStatusFilter, id: \.self) { filter in
                            FilterButton(title: filter, isSelected: filter == selectedGifticonStatusFilter) {
                                selectedGifticonStatusFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                //}
                
                
                if sortedGifticons.isEmpty {
                    Spacer()
                    Text("표시할 만료된 쿠폰이 없습니다")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            // 정렬된 기프티콘 리스트 사용
                            ForEach(sortedGifticons) { gifticon in
                                ZStack {
                                    GifticonCard(gifticon: gifticon, status: determineGifticonStatus(gifticon))
                                    
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
                                        .position(x: 90, y: 60)
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
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // 정렬 버튼 (최신순/오래된 순 토글)
                    Button {
                        sortByDateDesc.toggle()
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.black)
                    }
                    // 체크 모드 활성화를 통해 선택한 쿠폰을 휴지통으로 보냄
                    Button {
                        isCheckMode.toggle()
                    } label: {
                        Image(systemName: isCheckMode ? "xmark.circle" : "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .alert("이 쿠폰을 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    if let selected = selectedGifticon {
                        // 휴지통에 저장 하기 위해 추가
                        deletedGifticons.append(selected)
                        expiredGifticons.removeAll { $0.id == selected.id }
                        print("\(selected.productName) 삭제됨")
                    }
                    showDeleteAlert = false
                }
                Button("취소", role: .cancel) {
                    showDeleteAlert = false
                }
            } message: {
                Text("해당 쿠폰은 휴지통으로 이동 됩니다")
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
    let status: String?
    
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
                
                Text(status ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status == "사용 완료" ? Color.blue.opacity(0.7) : Color.gray.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(8)
                    .position(x: 140, y: 10)
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
    ExpiredView(deletedGifticons: .constant([]))
}
