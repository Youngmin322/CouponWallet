//
//  ContentView.swift
//  CouponWallet
//
//  Created by 조영민 on 3/6/25.
//

import SwiftUI
import PhotosUI
import SwiftData
import Vision

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

// 쿠폰 타입 enum
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
    
    // 스캐너 관련 상태 변수
    @State private var isShowingPhotoPicker = false
    @State private var isShowingScanner = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @StateObject private var scanManager = GifticonScanManager()
    
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
                                    // 터치했을 때 상세보기로 이동
                                    NavigationLink(destination: GifticonDetailView(gifticon: gifticon)) {
                                        GifticonCard(gifticon: gifticon, isExpired: false)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // 플러스 버튼
                Menu {
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        Label("직접 스캔하기", systemImage: "camera")
                    }
                    
                    Button(action: {
                        isShowingPhotoPicker = true
                    }) {
                        Label("갤러리에서 선택", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("내쿠폰함")
            .navigationBarTitleDisplayMode(.inline)
            
            // 갤러리에서 사진 선택 - 여러장 선택 가능
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) { oldValue, newValue in
                if !newValue.isEmpty {
                    // 각 이미지 처리
                    for item in newValue {
                        processImageDirectly(from: item)
                    }
                    // 처리 후 선택 항목 초기화
                    selectedItems = []
                }
            }
            
            // 카메라로 직접 스캔
            .sheet(isPresented: $isShowingScanner) {
                if #available(iOS 16.0, *) {
                    VisionKitScannerView { scannedImages in
                        if let firstImage = scannedImages.first {
                            // 카메라로 스캔한 경우에는 스캔 결과 화면 유지
                            scanManager.recognizeTextFromImage(firstImage)
                        }
                    }
                } else {
                    Text("iOS 16 이상에서만 지원합니다.")
                }
            }
            
            // 카메라 스캔에 대한 결과 화면 (유지)
            .sheet(isPresented: $scanManager.showScanResult) {
                ScanResultView(scanManager: scanManager)
            }
        }
    }
    
    // 선택한 이미지 직접 처리 (확인 화면 없이)
    private func processImageDirectly(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // 이미지 인식 처리
                        recognizeAndSaveGifticon(image: uiImage)
                    }
                }
            case .failure(let error):
                print("이미지 로드 오류: \(error)")
            }
        }
    }
    
    // 이미지 인식 및 기프티콘 직접 저장
    private func recognizeAndSaveGifticon(image: UIImage) {
        // 임시 ScanManager 생성
        let tempScanManager = GifticonScanManager()
        
        // 기본값 설정
        var imagePath = ""
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            if let savedPath = tempScanManager.saveImage(imageData) {
                imagePath = savedPath
            }
        }
        
        // 텍스트 인식 수행
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("텍스트 인식 오류: \(error)")
                DispatchQueue.main.async {
                    // 인식 실패시 기본 정보로 저장
                    saveBasicGifticon(imagePath: imagePath)
                }
                return
            }
            
            if let results = request.results as? [VNRecognizedTextObservation] {
                // 인식된 모든 텍스트 추출
                let recognizedTexts = results.compactMap { observation -> String? in
                    return observation.topCandidates(1).first?.string
                }
                
                // 텍스트에서 정보 추출
                tempScanManager.extractInformation(from: recognizedTexts)
                
                DispatchQueue.main.async {
                    // 인식된 정보로 기프티콘 저장
                    let newGifticon = Gifticon(
                        brand: tempScanManager.scanResult.brand,
                        productName: tempScanManager.scanResult.productName,
                        expirationDate: tempScanManager.scanResult.expirationDate,
                        isUsed: false,
                        imagePath: imagePath
                    )
                    
                    modelContext.insert(newGifticon)
                    try? modelContext.save()
                }
            }
        }
        
        // 최적의 인식을 위한 설정
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Request 수행 오류: \(error)")
            DispatchQueue.main.async {
                // 오류 발생시 기본 정보로 저장
                saveBasicGifticon(imagePath: imagePath)
            }
        }
    }
    
    // 기본 정보로 기프티콘 저장 (인식 실패 시)
    private func saveBasicGifticon(imagePath: String) {
        let newGifticon = Gifticon(
            brand: "기타",
            productName: "기프티콘",
            expirationDate: Date().addingTimeInterval(30*24*60*60), // 30일 후 만료
            isUsed: false,
            imagePath: imagePath
        )
        
        modelContext.insert(newGifticon)
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Gifticon.self, inMemory: true)
}
