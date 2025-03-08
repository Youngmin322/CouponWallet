//
//  GifticonDetailView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/7/25.
//

import SwiftUI
import SwiftData

// 기프티콘 상세 보기 화면
struct GifticonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let gifticon: Gifticon
    @State private var showingDeleteAlert = false
    @State private var markAsUsed = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 이미지
                if !gifticon.imagePath.isEmpty, let url = URL(string: gifticon.imagePath) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .overlay(
                            Text(gifticon.brand)
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(gifticon.brand)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(gifticon.productName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                    
                    HStack {
                        Text("유효기간")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(gifticon.formattedExpiryDate)
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("사용 여부")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(gifticon.isUsed ? "사용 완료" : "미사용")
                            .font(.subheadline)
                            .foregroundColor(gifticon.isUsed ? .blue : .green)
                    }
                    
                    Divider()
                    
                    // 버튼 행동들
                    HStack(spacing: 16) {
                        Button(action: {
                            markAsUsed.toggle()
                            gifticon.isUsed = markAsUsed
                            try? modelContext.save()
                        }) {
                            VStack {
                                Image(systemName: gifticon.isUsed ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.title2)
                                Text(gifticon.isUsed ? "사용 취소" : "사용 완료")
                                    .font(.caption)
                            }
                            .foregroundColor(gifticon.isUsed ? .blue : .primary)
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            VStack {
                                Image(systemName: "trash")
                                    .font(.title2)
                                Text("삭제")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical)
                }
                .padding()
            }
        }
        .navigationTitle("쿠폰 정보")
        .navigationBarTitleDisplayMode(.inline)
        .alert("쿠폰 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                deleteGifticon()
            }
        } message: {
            Text("정말로 이 쿠폰을 삭제하시겠습니까?")
        }
        .onAppear {
            markAsUsed = gifticon.isUsed
        }
    }
    
    private func deleteGifticon() {
        modelContext.delete(gifticon)
        try? modelContext.save()
    }
}
