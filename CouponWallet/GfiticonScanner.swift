//
//  GifticonScanner.swift
//  CouponWallet
//
//  Created by 조영민 on 3/7/25.
//

import SwiftUI
import Vision
import VisionKit
import SwiftData

// 스캔 결과를 처리하기 위한 구조체
struct ScanResult {
    var brand: String = ""
    var productName: String = ""
    var expirationDate: Date = Date().addingTimeInterval(30*24*60*60)
    var imagePath: String = ""
    var imageData: Data? = nil
}

// 이미지 스캔 및 텍스트 인식 매니저
class GifticonScanManager: ObservableObject {
    @Published var scanResult = ScanResult()
    @Published var isScanning = false
    @Published var showScanResult = false
    
    // 이미지에서 텍스트 인식하기
    func recognizeTextFromImage(_ image: UIImage) {
        isScanning = true
        
        // 새로운 스캔을 위해 결과 초기화
        scanResult = ScanResult()
        
        // 이미지 데이터 저장
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            scanResult.imageData = imageData
        }
        
        // Vision 요청 준비
        guard let cgImage = image.cgImage else {
            isScanning = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self, error == nil else {
                self?.isScanning = false
                return
            }
            
            if let results = request.results as? [VNRecognizedTextObservation] {
                // 인식된 모든 텍스트 추출
                let recognizedTexts = results.compactMap { observation -> String? in
                    return observation.topCandidates(1).first?.string
                }
                
                // 텍스트에서 정보 추출
                self.extractInformation(from: recognizedTexts)
                
                // UI 업데이트는 메인 스레드에서
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.showScanResult = true
                }
            }
        }
        
        // 최적의 인식을 위한 설정
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.revision = VNRecognizeTextRequestRevision3
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error: \(error)")
            isScanning = false
        }
    }
    
    // 인식된 텍스트에서 필요한 정보 추출 - 다른 클래스에서도 접근할 수 있도록 internal로 변경
    func extractInformation(from texts: [String]) {
        // 나중에 위치 기반 분석을 위해 모든 텍스트 저장
        var allTexts = texts
        
        // 브랜드 감지 - 확장된 목록과 부분 일치
        let brandKeywords = ["스타벅스", "Starbucks", "스타*", "이디야", "투썸", "CU", "GS25", "세븐일레븐",
                             "배스킨라빈스", "버거킹", "맥도날드", "롯데리아", "BBQ", "BHC", "교촌",
                             "네이버페이", "카카오페이", "다이소"]
        
        // 부분 문자열 일치로 브랜드 확인
        for text in texts {
            for brand in brandKeywords {
                if text.lowercased().contains(brand.lowercased()) {
                    scanResult.brand = brand
                    // 이 텍스트는 상품명 고려 대상에서 제외
                    if let index = allTexts.firstIndex(of: text) {
                        allTexts.remove(at: index)
                    }
                    break
                }
            }
            if !scanResult.brand.isEmpty { break }
        }
        
        // 유효기간 - "유효기간: 2025년 01월 29일" 같은 패턴 찾기
        let expiryPrefixes = ["유효기간", "만료일", "사용기한", "유효날짜", "유효기간:", "만료일:", "사용기한:"]
        
        for text in texts {
            // "유효기간: 2025년 01월 29일" 또는 "유효기간 2025년 01월 29일" 형식 직접 감지
            for prefix in expiryPrefixes {
                if text.contains(prefix) {
                    if let date = extractDateWithPrefix(from: text, prefix: prefix) {
                        scanResult.expirationDate = date
                        // 이 텍스트는 상품명 고려 대상에서 제외
                        if let index = allTexts.firstIndex(of: text) {
                            allTexts.remove(at: index)
                        }
                        break
                    }
                }
            }
            
            // 아직 날짜를 찾지 못했다면 일반 날짜 추출 시도
            if scanResult.expirationDate == Date().addingTimeInterval(30*24*60*60) {
                if let date = extractDate(from: text) {
                    scanResult.expirationDate = date
                    // 이 텍스트는 상품명 고려 대상에서 제외
                    if let index = allTexts.firstIndex(of: text) {
                        allTexts.remove(at: index)
                    }
                }
            }
        }
        
        // 길이와 위치 휴리스틱을 사용한 상품명 추출
        // 긴 텍스트를 우선으로 남은 텍스트 정렬
        let sortedTexts = allTexts.sorted { $0.count > $1.count }
        
        for text in sortedTexts {
            // 상품명이 아닐 가능성이 높은 텍스트는 건너뛰기
            if isDateString(text) || text.count < 4 || isBarcode(text) ||
               text.contains("교환처") || text.contains("주문번호") {
                continue
            }
            
            // 좋은 후보를 찾음
            scanResult.productName = text
            break
        }
        
        // 필요한 경우 기본값 설정
        if scanResult.brand.isEmpty {
            scanResult.brand = "기타"
        }
        
        if scanResult.productName.isEmpty && !sortedTexts.isEmpty {
            // 가장 긴 텍스트를 대체제로 사용
            scanResult.productName = sortedTexts[0]
        } else if scanResult.productName.isEmpty {
            scanResult.productName = "상품명 미인식"
        }
    }

    // 명시적 접두사("유효기간: 2025년 01월 29일")가 있는 날짜 추출 도우미
    private func extractDateWithPrefix(from text: String, prefix: String) -> Date? {
        guard let range = text.range(of: prefix) else { return nil }
        
        let dateText = text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        let dateFormatter = DateFormatter()
        
        // 접두사 뒤에 오는 다양한 날짜 형식 시도
        let formats = ["yyyy년 MM월 dd일", "yyyy년MM월dd일", "yyyy.MM.dd", "yyyy-MM-dd"]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateText) {
                return date
            }
        }
        
        // 직접 파싱에 실패한 경우 정규식으로 추출 시도
        return extractDate(from: dateText)
    }

    // 바코드 텍스트 감지 도우미
    private func isBarcode(_ text: String) -> Bool {
        let trimmed = text.replacingOccurrences(of: " ", with: "")
        // 대부분의 바코드는 숫자이며 8자리 이상
        return trimmed.count >= 8 && trimmed.allSatisfy { $0.isNumber }
    }
    
    // 텍스트에서 날짜 추출 (개선된 버전)
    private func extractDate(from text: String) -> Date? {
        // 날짜 형식 검색 (다양한 형식 지원)
        let dateFormats = [
            "yyyy.MM.dd", "yyyy-MM-dd", "yyyy년MM월dd일",
            "yyyy.M.d", "yyyy-M-d", "yyyy년M월d일",
            "yy.MM.dd", "yy-MM-dd", "yy년MM월dd일",
            "MM.dd.yyyy", "MM-dd-yyyy", "MM월dd일yyyy년"
        ]
        
        // 1. 정규식을 사용한 날짜 패턴 추출 시도
        let patterns = [
            "[0-9]{2,4}[.\\-년/\\s]*[0-9]{1,2}[.\\-월/\\s]*[0-9]{1,2}[일]?",  // yyyy(년) MM(월) dd(일)
            "[0-9]{1,2}[.\\-월/\\s]*[0-9]{1,2}[일]?[.\\-년/\\s]*[0-9]{2,4}"   // MM(월) dd(일) yyyy(년)
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let dateString = String(text[range])
                        
                        // 각 형식으로 파싱 시도
                        for format in dateFormats {
                            print("인식된 날짜 텍스트: \(dateString), 변환 시도 형식: \(format)")
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = format
                            if let date = dateFormatter.date(from: dateString) {
                                // 타당한 날짜 범위 확인 (현재부터 2년 이내)
                                let twoYearsLater = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
                                let sixYearsAgo = Calendar.current.date(byAdding: .year, value: -6, to: Date()) ?? Date()
                                if date > sixYearsAgo && date < twoYearsLater {
                                    return date
                                }
                            }
                        }
                    }
                }
            } catch {
                print("정규식 오류: \(error)")
            }
        }
        
        // 2. 특정 키워드와 함께 나타나는 숫자 찾기 ("~까지" 등)
        let expiryPhrases = ["까지", "~까지", "유효기간", "만료일"]
        for phrase in expiryPhrases {
            if text.contains(phrase) {
                // 키워드 주변의 날짜 패턴 찾기
                let components = text.components(separatedBy: phrase)
                if components.count > 1 {
                    // 키워드 앞이나 뒤의 텍스트에서 날짜 찾기
                    let surrounding = components[0] + components[1]
                    for pattern in patterns {
                        do {
                            let regex = try NSRegularExpression(pattern: pattern)
                            let matches = regex.matches(in: surrounding, range: NSRange(surrounding.startIndex..., in: surrounding))
                            
                            for match in matches {
                                if let range = Range(match.range, in: surrounding) {
                                    let dateString = String(surrounding[range])
                                    
                                    // 각 형식으로 파싱 시도
                                    for format in dateFormats {
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = format
                                        if let date = dateFormatter.date(from: dateString) {
                                            // 타당한 날짜 범위 확인
                                            let twoYearsLater = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
                                            if date > Date() && date < twoYearsLater {
                                                return date
                                            }
                                        }
                                    }
                                }
                            }
                        } catch {
                            print("정규식 오류: \(error)")
                        }
                    }
                }
            }
        }
        
        // 3. 특정 형식에 맞는지 직접 검사
        for format in dateFormats {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                // 타당한 날짜 범위 확인
                let twoYearsLater = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
                if date > Date() && date < twoYearsLater {
                    return date
                }
            }
        }
        
        // 기본값 - 30일 후로 설정
        return Date().addingTimeInterval(30*24*60*60)
    }
    
    // 텍스트가 날짜 형식인지 확인 (더 많은 패턴 인식)
    private func isDateString(_ text: String) -> Bool {
        let patterns = [
            "\\d{2,4}[.\\-년/]\\d{1,2}[.\\-월/]\\d{1,2}[일]?",  // yyyy.MM.dd, yy.MM.dd
            "\\d{1,2}[.\\-월/]\\d{1,2}[일]?[.\\-년/]\\d{2,4}",  // MM.dd.yyyy
            "\\d{1,2}[.\\-월/]\\d{1,2}[일]?",                  // MM.dd
            "\\d{4}[.\\-년/]\\d{1,2}"                          // yyyy.MM
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                if regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                    return true
                }
            } catch {
                return false
            }
        }
        
        // 추가로 날짜 관련 키워드 확인
        let dateKeywords = ["유효기간", "만료일", "사용기한", "까지", "~까지", "유효", "만료", "expiry", "valid"]
        for keyword in dateKeywords {
            if text.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    // 이미지 저장
    func saveImage(_ imageData: Data) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            print("이미지 저장 오류: \(error)")
            return nil
        }
    }
}

// 스캔 결과 확인 및 편집 화면 (카메라로 스캔할 때만 사용)
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

// iOS 16 이상에서 사용할 수 있는 VisionKit 스캐너 뷰
@available(iOS 16.0, *)
struct VisionKitScannerView: UIViewControllerRepresentable {
    var didFinishScanning: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: VisionKitScannerView
        
        init(parent: VisionKitScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // 스캔 화면 캡처
            let image = dataScanner.view.asImage() // UIImage 타입이 아닐 경우 에러 발생
            parent.didFinishScanning([image])
            dataScanner.dismiss(animated: true)
        }
    }
}
