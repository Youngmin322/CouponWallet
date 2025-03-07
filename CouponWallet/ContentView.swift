//
//  ContentView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0 // 0: 보유, 1: 사용·만료, 2: 설정
    // 삭제된 기프티콘을 저장하는 배열 (휴지통 기능을 위해 사용)
    @State var deletedGifticons: [Gifticon] = []
    var body: some View {
        TabView(selection: $selectedTab) {
            // 보유 탭
            AvailableGifticonView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)
            
            // 사용·만료 탭
            ExpiredView(deletedGifticons: $deletedGifticons)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("사용·만료")
                }
                .tag(1)
            
            // 설정 탭
            SettingView(deletedGifticons: $deletedGifticons)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
                .tag(2)
        }
    }
}

// 쿠폰 타입 enum (만약 다른 곳에서 사용하지 않는다면 제거 가능합니다)
enum GifticonType {
    case available
    case expired
}

// 사용 가능한 기프티콘 뷰
struct AvailableGifticonView: View {
    @State private var selectedFilter = "전체"
    let filters = ["전체", "스타벅스", "치킨", "CU", "GS25", "기타"]
    
    @Query private var availableGifticons: [Gifticon]
    
    init() {
        let now = Date()
        // 사용 가능한 기프티콘: 만료되지 않았고 사용되지 않은 것
        let predicate = #Predicate<Gifticon> { gifticon in
            !gifticon.isUsed && gifticon.expirationDate > now
        }
        _availableGifticons = Query(filter: predicate, sort: [SortDescriptor(\.expirationDate)])
    }
    
    // 필터링된 쿠폰 목록
    var filteredGifticons: [Gifticon] {
        if selectedFilter == "전체" {
            return availableGifticons
        } else {
            return availableGifticons.filter { $0.brand == selectedFilter }
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
                    Text("표시할 쿠폰이 없습니다")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredGifticons) { gifticon in
                                GifticonCard(gifticon: gifticon, status: nil)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("내쿠폰함")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView(deletedGifticons: Gifticon.dummyData)
        .modelContainer(for: Gifticon.self, inMemory: true)
}
