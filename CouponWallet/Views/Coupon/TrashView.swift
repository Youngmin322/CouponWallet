//
//  TrashView.swift
//  CouponWallet
//
//  Created by Reimos on 3/7/25.
//

import SwiftUI

struct TrashView: View {
    // 삭제 확인 알림창을 표시할지 여부
    @State private var showDeleteAlert: Bool = false
    // 체크 모드 (여러 개 선택 가능)
    @State private var isCheckMode: Bool = false
    // 선택한 기프티콘
    @State private var selectedGifticon: Gifticon?
    // 삭제된 기프티콘을 저장하는 배열 (휴지통 기능을 위해 사용)
    @Binding var deletedGifticons: [Gifticon]
    
    // isUsed 및 expirationDate를 기반으로 상태 결정
    func determineGifticonStatus(_ gifticon: Gifticon) -> String {
        return gifticon.isUsed ? GifticonStatus.used.rawValue : GifticonStatus.expired.rawValue
    }
    
    var body: some View {
       // NavigationStack {
            VStack(spacing: 0) {
                if deletedGifticons.isEmpty {
                    Spacer()
                    Text("휴지통에 쿠폰이 없습니다")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(deletedGifticons) { gifticon in
                                ZStack {
                                    GifticonCard(gifticon: gifticon, status: determineGifticonStatus(gifticon))

                                    if isCheckMode {
                                        Button {
                                            selectedGifticon = gifticon
                                            showDeleteAlert = true
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                // 쿠폰이 선택되면 red로 색상 변경
                                                .foregroundColor(selectedGifticon == gifticon ? .red : .gray)
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
            .navigationTitle("휴지통")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                        deletedGifticons.removeAll { $0.id == selected.id }
                        print("\(selected.productName) 삭제됨")
                    }
                    showDeleteAlert = false
                    // 삭제 후 선택 초기화 - 아이콘 회색
                    selectedGifticon = nil
                }
                Button("취소", role: .cancel) {
                    showDeleteAlert = false
                    // 삭제 후 선택 초기화 - 아이콘 회색
                    selectedGifticon = nil
                }
            } message: {
                Text("해당 쿠폰은 완전히 삭제됩니다")
            }
        //}
    }
}

#Preview {
    TrashView(deletedGifticons: .constant([]))
}
