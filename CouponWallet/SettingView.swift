//
//  SettingView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("계정")) {
                    NavigationLink("프로필 설정", destination: Text("프로필 설정 화면"))
                    NavigationLink("알림 설정", destination: Text("알림 설정 화면"))
                    NavigationLink("휴지통", destination: Text("기프티콘 휴지통 화면"))
                }
                
                Section(header: Text("앱 설정")) {
                    NavigationLink("테마 설정", destination: Text("테마 설정 화면"))
                    NavigationLink("언어 설정", destination: Text("언어 설정 화면"))
                    NavigationLink("정렬 기준", destination: Text("정렬 기준 화면"))
                }
                
                Section(header: Text("정보")) {
                    Text("앱 버전 1.0.0")
                    NavigationLink("개인정보 처리방침", destination: Text("개인정보 처리방침 화면"))
                    NavigationLink("이용약관", destination: Text("이용약관 화면"))
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
