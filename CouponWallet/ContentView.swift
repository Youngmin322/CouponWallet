//
//  ContentView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0 // 0: 보유, 1: 사용·만료, 2: 설정
    
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
            ExpiredView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("사용·만료")
                }
                .tag(1)
            
            // 설정 탭
            SettingView()
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
    @Environment(\.modelContext) private var modelContext
    
    // PhotoPicker 관련 상태 변수
    @State private var isShowingPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    
    // 새 기프티콘 정보 상태 변수
    @State private var newBrand = ""
    @State private var newProductName = ""
    @State private var newExpirationDate = Date().addingTimeInterval(30*24*60*60) // 기본 30일 후
    @State private var newPrice = ""
    @State private var newOriginalPrice = ""
    
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
            ZStack(alignment: .bottomTrailing) {
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
                                    GifticonCard(gifticon: gifticon, isExpired: false)
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // 플러스 버튼
                Button(action: {
                    // 사진 피커를 바로 띄우기
                    isShowingPhotoPicker = true
                }, label: {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                        .padding()
                })
                .padding()
            }
            .navigationTitle("내쿠폰함")
            .navigationBarTitleDisplayMode(.inline)
            
            // 사진 선택 기능
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedItems, maxSelectionCount: 0, matching: .images) // maxSelectionCount: 0 -> 무제한 선택
            .onChange(of: selectedItems) { oldValue, newValue in
                // 선택된 항목들이 변경될 때마다 처리되는 로직
                print("선택된 이미지: \(newValue.count)개")
            }
            
            // "추가" 버튼: 포토 피커에서 선택한 이미지를 처리
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedItems, maxSelectionCount: 0, matching: .images)
            .onChange(of: selectedItems) { _, newValue in
                // 선택된 항목이 있을 때 처리
                if !newValue.isEmpty {
                    addSelectedImages()
                }
            }
        }
    }
    
    // 선택된 이미지들을 처리하는 함수
    private func addSelectedImages() {
        for item in selectedItems {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        // 이미지를 처리하는 코드 (예: UI에 표시하거나 저장)
                        print("이미지 처리됨: \(uiImage)")
                        // 예: 모델에 저장하거나 다른 작업을 수행
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
}



    
#Preview {
    ContentView()
        .modelContainer(for: Gifticon.self, inMemory: true)
}
