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
    // 삭제된 기프티콘을 저장하는 배열 (휴지통 기능을 위해 사용)
    @State var deletedGifticons: [Gifticon] = []
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
            ExpiredView(deletedGifticons: $deletedGifticons)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("사용·만료")
                }
                .tag(1)
            
            // 설정 탭
            SettingView(deletedGifticons: $deletedGifticons)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
                .tag(2)
        }
        .tint(.orange)
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
    
    // 사용 가능한 기프티콘 뷰 init 부분 수정
    init() {
        let now = Date()
        // 사용 가능한 기프티콘: 만료되지 않았고 사용되지 않은 것
        let predicate = #Predicate<Gifticon> { gifticon in
            !gifticon.isUsed && gifticon.expirationDate > now
        }
        _availableGifticons = Query(filter: predicate, sort: [SortDescriptor(\.expirationDate)])
    }
    
    // 필터링된 쿠폰 목록 - 단순화된 방식으로 분리
    var filteredGifticons: [Gifticon] {
        return getFilteredGifticons()
    }
    
    // 필터링 로직을 별도 함수로 분리
    private func getFilteredGifticons() -> [Gifticon] {
        if selectedFilter == "전체" {
            return availableGifticons
        } else {
            return availableGifticons.filter { $0.brand == selectedFilter }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                mainContentView()
                addButtonMenu()
            }
            .navigationTitle("내쿠폰함")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) { oldValue, newValue in
                handleSelectedPhotos(newValue)
            }
            .sheet(isPresented: $isShowingScanner) {
                scannerView()
            }
            .sheet(isPresented: $scanManager.showScanResult) {
                ScanResultView(scanManager: scanManager)
            }
        }
    }
    
    // 메인 콘텐츠 뷰
    private func mainContentView() -> some View {
        VStack(spacing: 0) {
            filterOptionsView()
            gifticonGridView()
        }
    }
    
    // 필터 옵션 뷰
    private func filterOptionsView() -> some View {
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
    }
    
    // 기프티콘 그리드 뷰
    private func gifticonGridView() -> some View {
        Group {
            if filteredGifticons.isEmpty {
                emptyStateView()
            } else {
                gifticonGridContent()
            }
        }
    }
    
    // 빈 상태 뷰
    private func emptyStateView() -> some View {
        VStack {
            Spacer()
            Text("표시할 쿠폰이 없습니다")
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    // 기프티콘 그리드 내용
    private func gifticonGridContent() -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredGifticons) { gifticon in
                    NavigationLink(destination: SelectedCouponView(selectedGifticon: gifticon)) {
                        GifticonCard(gifticon: gifticon, status: "available")
                    }
                }
            }
            .padding()
        }
    }
    
    // 추가 버튼 메뉴
    private func addButtonMenu() -> some View {
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
    
    // 스캐너 뷰
    private func scannerView() -> some View {
        Group {
            if #available(iOS 16.0, *) {
                VisionKitScannerView { scannedImages in
                    handleScannedImages(scannedImages)
                }
            } else {
                Text("iOS 16 이상에서만 지원합니다.")
            }
        }
    }
    
    // 스캔된 이미지 처리
    private func handleScannedImages(_ images: [UIImage]) {
        if let firstImage = images.first {
            scanManager.recognizeTextFromImage(firstImage)
        }
    }
    
    // 선택된 사진 처리
    private func handleSelectedPhotos(_ items: [PhotosPickerItem]) {
        if !items.isEmpty {
            for item in items {
                processImageDirectly(from: item)
            }
            selectedItems = []
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
        let imagePath = saveImageAndGetPath(image, manager: tempScanManager)
        
        // 텍스트 인식 수행
        performTextRecognition(image: image, imagePath: imagePath, scanManager: tempScanManager)
    }
    
    // 이미지 저장 및 경로 반환
    private func saveImageAndGetPath(_ image: UIImage, manager: GifticonScanManager) -> String {
        var imagePath = ""
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            if let savedPath = manager.saveImage(imageData) {
                imagePath = savedPath
            }
        }
        return imagePath
    }
    
    // 텍스트 인식 수행
    private func performTextRecognition(image: UIImage, imagePath: String, scanManager: GifticonScanManager) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                saveBasicGifticon(imagePath: imagePath)
            }
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = createTextRecognitionRequest(imagePath: imagePath, scanManager: scanManager)
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Request 수행 오류: \(error)")
            DispatchQueue.main.async {
                saveBasicGifticon(imagePath: imagePath)
            }
        }
    }
    
    // 텍스트 인식 요청 생성
    private func createTextRecognitionRequest(imagePath: String, scanManager: GifticonScanManager) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("텍스트 인식 오류: \(error)")
                DispatchQueue.main.async {
                    self.saveBasicGifticon(imagePath: imagePath)
                }
                return
            }
            
            self.processRecognizedResults(request: request, imagePath: imagePath, scanManager: scanManager)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        return request
    }
    
    // 인식된 결과 처리
    private func processRecognizedResults(request: VNRequest, imagePath: String, scanManager: GifticonScanManager) {
        if let results = request.results as? [VNRecognizedTextObservation] {
            let recognizedTexts = results.compactMap { observation -> String? in
                return observation.topCandidates(1).first?.string
            }
            
            scanManager.extractInformation(from: recognizedTexts)
            
            DispatchQueue.main.async {
                self.saveGifticonFromScanResult(imagePath: imagePath, scanManager: scanManager)
            }
        } else {
            DispatchQueue.main.async {
                self.saveBasicGifticon(imagePath: imagePath)
            }
        }
    }
    
    // 스캔 결과로부터 기프티콘 저장
    private func saveGifticonFromScanResult(imagePath: String, scanManager: GifticonScanManager) {
        let newGifticon = Gifticon(
            brand: scanManager.scanResult.brand,
            productName: scanManager.scanResult.productName,
            expirationDate: scanManager.scanResult.expirationDate,
            isUsed: false,
            imagePath: imagePath
        )
        
        modelContext.insert(newGifticon)
        try? modelContext.save()
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

//#Preview {
//    ContentView(deletedGifticons: Gifticon.)
//        .modelContainer(for: Gifticon.self, inMemory: true)
//}
