//
//  ThemeView.swift
//  CouponWallet
//
//  Created by Reimos on 3/8/25.
//

import SwiftUI
/*
 테스트로 ThemeView에서 공유 아이콘 클릭 시 갤러리에 저장
 */
struct ThemeView: View {
    // 스크린샷 저장
    @State private var showToast = false
    @AppStorage("isDarkMode") private var isDarkMode = false  // 다크 모드 상태 저장
    @Environment(\.colorScheme) var colorScheme  // 현재 다크/라이트 모드 확인

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("디스플레이 설정").foregroundColor(colorScheme == .dark ? .white : .black)) {
                    
                    // 다크 모드 버튼
                    Button(action: {
                        isDarkMode = true
                    }) {
                        HStack {
                            Text("🌙 다크 모드")
                                .foregroundColor(colorScheme == .dark ? .white : .black) // 다크 모드에서는 흰색, 라이트 모드에서는 검은색
                            Spacer()
                            if isDarkMode { Image(systemName: "checkmark").foregroundColor(colorScheme == .dark ? .white : .black) }
                        }
                    }
                    
                    // 라이트 모드 버튼
                    Button(action: {
                        isDarkMode = false
                    }) {
                        HStack {
                            Text("☀️ 라이트 모드")
                                .foregroundColor(colorScheme == .dark ? .white : .black) // 다크 모드에서는 흰색, 라이트 모드에서는 검은색
                            Spacer()
                            if !isDarkMode { Image(systemName: "checkmark").foregroundColor(colorScheme == .dark ? .white : .black) }
                        }
                    }
                }
            }
            .navigationTitle("화면 테마")
            // 앱 전체에 다크 모드 적용
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        // 버튼을 누르면 캡쳐 후 갤러리에 저장
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                   
                    // iOS 15 이상에서 화면 캡처 후 저장
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let screenshot = window.rootViewController?.view.changeUIImage() {
                        // 캡쳐 이미지 저장 Toast 메시지
                        showToast = true
                        saveCaptureImageToAlbum(screenshot)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showToast = false
                        }
                        
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        // 캡쳐 이미지를 저장하면 Toast 메시지로 알려줌
        if showToast {
            VStack {
                Text("스크린샷 앨범 저장 성공")
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .transition(.opacity)
            .animation(.easeInOut, value: showToast)
            .padding(.bottom, 50)
            
        }
    }
    
}

#Preview {
    ThemeView()
}
