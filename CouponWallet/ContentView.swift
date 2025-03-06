//
//  ContentView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            List {
                // 구현 예정...
            }
            .navigationTitle("기프티콘")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 새 기프티콘 추가
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
