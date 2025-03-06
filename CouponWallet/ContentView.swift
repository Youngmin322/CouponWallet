//
//  ContentView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0 // 0: 보유, 1: 사용·만료, 2: 설정
    @State private var selectedFilter = "사용순"
    let filters = ["스타벅스", "치킨", "CU", "GS25", "다이소"]
    
    // 샘플 데이터
    let coupons = [
        Coupon(store: "스타벅스", name: "카페아메리카노 T", price: 4150, originalPrice: 4700, discount: 12, expiryDate: "2024.03.26"),
        Coupon(store: "스타벅스", name: "카페아메리카노 T", price: 4050, originalPrice: 4700, discount: 14, expiryDate: "2024.04.29"),
        Coupon(store: "스타벅스", name: "카페아메리카노 T", price: 4020, originalPrice: 4700, discount: 14, expiryDate: "2024.10.31"),
        Coupon(store: "GS25", name: "빙그레)바나나우유....", price: 1200, originalPrice: 1800, discount: 33, expiryDate: "2024.02.18")
    ]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 보유 탭
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
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(coupons) { coupon in
                                CouponCard(coupon: coupon)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("내쿠폰함")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "gift.fill")
                Text("보유")
            }
            .tag(0)
            
            // 사용·만료 탭
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
                    
                    // 사용·만료 기프티콘 그리드 (여기서는 예시로 동일 데이터 사용)
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(coupons) { coupon in
                                CouponCard(coupon: coupon)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("사용·만료")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("사용·만료")
            }
            .tag(1)
            
            // 설정 탭
            NavigationView {
                List {
                    Section(header: Text("계정")) {
                        Text("프로필 설정")
                        Text("알림 설정")
                    }
                    
                    Section(header: Text("앱 설정")) {
                        Text("테마 설정")
                        Text("언어 설정")
                        Text("정렬 기준")
                    }
                    
                    Section(header: Text("정보")) {
                        Text("앱 버전 1.0.0")
                        Text("개인정보 처리방침")
                        Text("이용약관")
                    }
                }
                .navigationTitle("설정")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("설정")
            }
            .tag(2)
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
struct CouponCard: View {
    let coupon: Coupon
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image("couponImage") // 실제 앱에서는 각 쿠폰의 이미지로 대체
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.1))
                
                Text("만료")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(8)
            }
            
            Text(coupon.store)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(coupon.name)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Text("\(coupon.price.formattedWithComma)원")
                    .fontWeight(.bold)
                
                Text("\(coupon.discount)%")
                    .foregroundColor(.red)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Text("\(coupon.originalPrice.formattedWithComma)원")
                .font(.caption)
                .foregroundColor(.gray)
                .strikethrough()
            
            Text("\(coupon.expiryDate) 까지")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Coupon 모델
struct Coupon: Identifiable {
    let id = UUID()
    let store: String
    let name: String
    let price: Int
    let originalPrice: Int
    let discount: Int
    let expiryDate: String
}

// Int 확장 - 금액 형식
extension Int {
    var formattedWithComma: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

#Preview {
    ContentView()
}
