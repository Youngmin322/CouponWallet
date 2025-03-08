//
//  ThemeView.swift
//  CouponWallet
//
//  Created by Reimos on 3/8/25.
//

import SwiftUI

struct ThemeView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false  // 다크 모드 상태 저장
    @Environment(\.colorScheme) var colorScheme  // 현재 다크/라이트 모드 확인

    var body: some View {
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
        .preferredColorScheme(isDarkMode ? .dark : .light) // 앱 전체에 다크 모드 적용
    }
}

#Preview {
    ThemeView()
}
