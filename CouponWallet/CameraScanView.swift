//
//  CameraScanView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/10/25.
//

import SwiftUI
// MARK: - 스캔 결과 화면

struct ScanResultView: View {
    @ObservedObject var scanManager: GifticonScanManager
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var brand: String
    @State private var productName: String
    @State private var expirationDate: Date
    
    init(scanManager: GifticonScanManager) {
        self.scanManager = scanManager
        _brand = State(initialValue: scanManager.scanResult.brand)
        _productName = State(initialValue: scanManager.scanResult.productName)
        _expirationDate = State(initialValue: scanManager.scanResult.expirationDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("기프티콘 이미지")) {
                    if let imageData = scanManager.scanResult.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
                
                Section(header: Text("기프티콘 정보")) {
                    TextField("브랜드", text: $brand)
                    TextField("상품명", text: $productName)
                    DatePicker("유효기간", selection: $expirationDate, displayedComponents: .date)
                }
            }
            .navigationTitle("스캔 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveGifticon()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveGifticon() {
        // 이미지 저장
        var imagePath = ""
        if let imageData = scanManager.scanResult.imageData {
            if let savedPath = scanManager.saveImage(imageData) {
                imagePath = savedPath
            }
        }
        
        // SwiftData에 기프티콘 정보 저장
        let newGifticon = Gifticon(
            brand: brand,
            productName: productName,
            expirationDate: expirationDate,
            isUsed: false,
            imagePath: imagePath
        )
        
        modelContext.insert(newGifticon)
    }
}
