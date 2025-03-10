import SwiftUI
import Vision
import VisionKit
import SwiftData

struct ScanResult {
    var brand: String = ""
    var productName: String = ""
    var expirationDate: Date = TextAnalyzer.defaultExpirationDate
    var imagePath: String = ""
    var imageData: Data? = nil
}

struct TextAnalyzer {
    // 상수로 정의하여 재사용
    static let defaultExpirationPeriod: TimeInterval = 30 * 24 * 60 * 60  // 30일
    static var defaultExpirationDate: Date {
        return Date().addingTimeInterval(defaultExpirationPeriod)
    }
    
    static let dateFormats = [
        "yyyy년MM월dd일", "yyyy년 MM월 dd일", "yyyy.MM.dd", "yyyy-MM-dd",
        "yyyy년M월d일", "yyyy년 M월 d일", "yyyy.M.d", "yyyy-M-d",
        "yy.MM.dd", "yy-MM-dd", "yy년 MM월 dd일",
        "MM.dd.yyyy", "MM-dd-yyyy", "MM월 dd일 yyyy년"
    ]
    
    static let datePatterns = [
        "20\\d{2}[.\\-년/\\s]*\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?",
        "\\d{4}[.\\-년/\\s]*\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?",
        "\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?[.\\-년/\\s]*20\\d{2}"
    ]
    
    static let yearPattern = "20\\d{2}[년]?"
    static let monthPattern = "\\d{1,2}[월]?"
    static let dayPattern = "\\d{1,2}[일]?"
    
    static let dateKeywords = ["유효기간", "만료일", "사용기한", "까지", "~까지", "유효", "만료"]
    static let knownLabels = ["유효기간", "만료일", "사용기한", "교환처", "주문번호", "결제금액", "상품명"]
    
    /// 바코드일 가능성이 높은지 확인 (단순화됨)
    static func isLikelyBarcode(_ text: String) -> Bool {
        // 숫자와 공백만 있는지 확인
        let hasOnlyDigitsAndSpaces = text.allSatisfy { $0.isNumber || $0.isWhitespace }
        if !hasOnlyDigitsAndSpaces { return false }
        
        let justDigits = text.replacingOccurrences(of: " ", with: "")
        
        // 바코드 길이 확인 또는 바코드 패턴 확인 (간소화)
        return justDigits.count >= 8 && justDigits.count <= 16 ||
               text.components(separatedBy: .whitespacesAndNewlines)
                   .allSatisfy { $0.count == 4 && $0.allSatisfy { $0.isNumber } }
    }
    
    /// 순수 날짜 패턴만 있는지 확인
    static func containsPureDatePattern(_ text: String) -> Bool {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // "2024년 02월 02일" 패턴 확인
        if cleanedText.contains("년") && cleanedText.contains("월") && cleanedText.contains("일") {
            var hasYear = false, hasMonth = false, hasDay = false
            
            if let _ = try? NSRegularExpression(pattern: yearPattern).firstMatch(
                in: cleanedText,
                range: NSRange(location: 0, length: (cleanedText as NSString).length)
            ) {
                hasYear = true
            }
            
            if let _ = try? NSRegularExpression(pattern: monthPattern).firstMatch(
                in: cleanedText,
                range: NSRange(location: 0, length: (cleanedText as NSString).length)
            ) {
                hasMonth = true
            }
            
            if let _ = try? NSRegularExpression(pattern: dayPattern).firstMatch(
                in: cleanedText,
                range: NSRange(location: 0, length: (cleanedText as NSString).length)
            ) {
                hasDay = true
            }
            
            if hasYear && hasMonth && hasDay {
                return true
            }
        }
        
        // 기타 날짜 패턴 확인
        let pureDatePatterns = [
            "^20\\d{2}[년.\\-/]\\s*\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?$",
            "^\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?[.\\-/]?\\s*20\\d{2}[년]?$",
            "^20\\d{2}[년.\\-/]\\s*\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?까지$"
        ]
        
        for pattern in pureDatePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: cleanedText.utf16.count)
                if regex.firstMatch(in: cleanedText, options: [], range: range) != nil {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }
    
    /// 문자열에서 날짜 문자열 추출
    static func extractDateString(from text: String) -> String? {
        for pattern in datePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let matchRange = Range(match.range, in: text) {
                    return String(text[matchRange])
                }
            } catch {
                continue
            }
        }
        return nil
    }
    
    /// 문자열에서 날짜 추출 (주 함수) - 중복 제거됨
    static func extractDate(from text: String, checkBarcode: Bool = true) -> Date? {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "~", with: "")
        
        // 바코드 체크가 필요하고 바코드로 보이면 건너뛰기
        if checkBarcode && isLikelyBarcode(cleanedText) {
            return nil
        }
        
        // 유효한 날짜 범위 설정
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        let fiveYearsLater = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        
        // 1. 날짜 형식 직접 시도
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: cleanedText),
               date > fiveYearsAgo && date < fiveYearsLater {
                return date
            }
        }
        
        // 2. 날짜 문자열 추출 후 변환 시도
        if let dateString = extractDateString(from: cleanedText) {
            let cleanDateString = dateString.replacingOccurrences(of: "까지", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 형식으로 날짜 시도
            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: cleanDateString),
                   date > fiveYearsAgo && date < fiveYearsLater {
                    return date
                }
            }
            
            // 년, 월, 일 개별 추출 시도
            var year: Int?, month: Int?, day: Int?
            
            if let yearMatch = try? NSRegularExpression(pattern: yearPattern).firstMatch(
                in: cleanDateString,
                range: NSRange(location: 0, length: (cleanDateString as NSString).length)
            ),
               let yearRange = Range(yearMatch.range, in: cleanDateString) {
                let yearStr = cleanDateString[yearRange].replacingOccurrences(of: "년", with: "")
                year = Int(yearStr)
            }
            
            if let monthMatch = try? NSRegularExpression(pattern: monthPattern).firstMatch(
                in: cleanDateString,
                range: NSRange(location: 0, length: (cleanDateString as NSString).length)
            ),
               let monthRange = Range(monthMatch.range, in: cleanDateString) {
                let monthStr = cleanDateString[monthRange].replacingOccurrences(of: "월", with: "")
                month = Int(monthStr)
            }
            
            if let dayMatch = try? NSRegularExpression(pattern: dayPattern).firstMatch(
                in: cleanDateString,
                range: NSRange(location: 0, length: (cleanDateString as NSString).length)
            ),
               let dayRange = Range(dayMatch.range, in: cleanDateString) {
                let dayStr = cleanDateString[dayRange].replacingOccurrences(of: "일", with: "")
                day = Int(dayStr)
            }
            
            // 년월일로 날짜 생성
            if let year = year, let month = month, let day = day {
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day
                
                if let date = Calendar.current.date(from: components),
                   date > fiveYearsAgo && date < fiveYearsLater {
                    return date
                }
            }
        }
        
        // 3. 키워드 뒤의 날짜 확인
        for keyword in dateKeywords {
            if cleanedText.contains(keyword) {
                let components = cleanedText.components(separatedBy: keyword)
                if components.count > 1 {
                    let textAfterKeyword = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let date = extractDate(from: textAfterKeyword, checkBarcode: false) {
                        return date
                    }
                }
            }
        }
        
        // 4. "까지" 문자열 처리
        if cleanedText.contains("까지") {
            let textWithoutUntil = cleanedText.replacingOccurrences(of: "까지", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: textWithoutUntil),
                   date > fiveYearsAgo && date < fiveYearsLater {
                    return date
                }
            }
        }
        
        // 기본값 반환
        return defaultExpirationDate
    }
    
    /// 텍스트에서 레이블-값 쌍 찾기
    static func findLabelValuePairs(from texts: [String]) -> [String: String] {
        // 인식된 모든 텍스트를 줄바꿈으로 분리
        let allLines = texts.flatMap { $0.components(separatedBy: .newlines) }
        var pairs: [String: String] = [:]
        
        // 1. "레이블: 값" 형식 찾기
        for line in allLines {
            for label in knownLabels {
                if line.contains("\(label):") || line.contains("\(label) :") {
                    let components = line.components(separatedBy: ":")
                    if components.count >= 2 {
                        let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        pairs[label] = value
                    }
                }
            }
        }
        
        // 2. 가로 정렬된 레이블-값 쌍 찾기
        for (index, line) in allLines.enumerated() {
            for label in knownLabels {
                if pairs[label] != nil { continue } // 이미 발견된 레이블은 건너뜀
                
                if line.trimmingCharacters(in: .whitespacesAndNewlines) == label {
                    // 탭/공백으로 구분된 경우
                    let components = line.components(separatedBy: CharacterSet(charactersIn: "\t    "))
                        .filter { !$0.isEmpty }
                    
                    if components.count >= 2 {
                        let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        pairs[label] = value
                    } else if index + 1 < allLines.count {
                        // 다음 줄에 값이 있을 수 있음
                        let nextLine = allLines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !knownLabels.contains(where: { nextLine.hasPrefix($0) }) {
                            pairs[label] = nextLine
                        }
                    }
                }
            }
        }
        
        // 3. 레이블과 값이 떨어져 있는 특별 케이스 처리
        var labelIndices: [String: Int] = [:]
        for (index, line) in allLines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            for label in knownLabels {
                if trimmedLine == label || trimmedLine.hasPrefix(label) {
                    labelIndices[label] = index
                    break
                }
            }
        }
        
        for (label, labelIndex) in labelIndices {
            if pairs[label] != nil { continue }
            
            _ = allLines[labelIndex]
            
            // 날짜 패턴 확인
            if label.contains("기간") || label.contains("만료") || label.contains("사용") {
                for text in texts {
                    if containsPureDatePattern(text) {
                        if let dateString = extractDateString(from: text) {
                            pairs[label] = dateString
                            break
                        }
                    }
                }
            }
        }
        
        // 4. 유효기간 레이블 없이 날짜만 있는 경우
        if pairs["유효기간"] == nil && pairs["만료일"] == nil && pairs["사용기한"] == nil {
            for text in texts {
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if (trimmedText.contains("까지") || trimmedText.hasSuffix("까지")) && containsPureDatePattern(trimmedText) {
                    pairs["유효기간"] = trimmedText
                    break
                }
                
                if containsPureDatePattern(trimmedText) {
                    pairs["유효기간"] = trimmedText
                    break
                }
            }
        }
        return pairs
    }
}

// MARK: - 기프티콘 스캔 매니저

class GifticonScanManager: ObservableObject {
    @Published var scanResult = ScanResult()
    @Published var isScanning = false
    @Published var showScanResult = false
    
    // 브랜드 키워드 목록
    private let brandKeywords = [
        "스타벅스", "Starbucks", "이디야", "투썸플레이스", "CU", "GS25",
        "세븐일레븐", "베스킨라빈스", "버거킹", "맥도날드", "롯데리아",
        "BBQ", "BHC", "교촌", "네이버페이", "카카오페이"
    ]
    
    // MARK: - 이미지에서 텍스트 인식
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
        request.recognitionLanguages = ["ko-KR"]
        request.revision = VNRecognizeTextRequestRevision3
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error: \(error)")
            isScanning = false
        }
    }
    
    func extractInformation(from texts: [String]) {
        // 레이블-값 쌍 찾기
        let pairs = TextAnalyzer.findLabelValuePairs(from: texts)
        
        // 1. 브랜드 추출
        extractBrand(from: texts, pairs: pairs)
        
        // 2. 유효기간 추출
        extractExpirationDate(from: texts, pairs: pairs)
        
        // 3. 상품명 추출 - 이미 처리된 텍스트를 고려하여 추출
        extractProductName(from: texts, pairs: pairs)
    }

    // MARK: - 브랜드 추출 (개선됨)
    private func extractBrand(from texts: [String], pairs: [String: String]) {
        // 1. 레이블-값 쌍에서 브랜드 찾기
        if let exchange = pairs["교환처"], !exchange.isEmpty {
            scanResult.brand = exchange
            return
        }
        
        // 2. 텍스트에서 브랜드 키워드 찾기
        for text in texts {
            for brand in brandKeywords {
                if text.lowercased().contains(brand.lowercased()) {
                    scanResult.brand = brand
                    return
                }
            }
        }
        
        // 3. 브랜드를 찾지 못했을 경우 기본값 설정
        if scanResult.brand.isEmpty {
            scanResult.brand = "기타"
        }
    }

    // MARK: - 유효기간 추출
    private func extractExpirationDate(from texts: [String], pairs: [String: String]) {
        // 1. 레이블-값 쌍에서 유효기간 찾기
        if let expiryDate = pairs["유효기간"] ?? pairs["만료일"] ?? pairs["사용기한"], !expiryDate.isEmpty {
            if let date = TextAnalyzer.extractDate(from: expiryDate) {
                scanResult.expirationDate = date
                return
            }
        }
        
        // 2. 텍스트에서 날짜 패턴 찾기
        let dateTexts = texts.filter {
            $0.contains("까지") ||
            $0.hasSuffix("까지") ||
            TextAnalyzer.containsPureDatePattern($0)
        }
        
        for text in dateTexts {
            if let date = TextAnalyzer.extractDate(from: text) {
                // 기본값과 다른지 확인
                if !Calendar.current.isDate(date, inSameDayAs: TextAnalyzer.defaultExpirationDate) {
                    scanResult.expirationDate = date
                    return
                }
            }
        }
        
        // 3. 마지막 수단으로 일반 텍스트에서 날짜 패턴 찾기
        for text in texts {
            if let date = TextAnalyzer.extractDate(from: text) {
                if !Calendar.current.isDate(date, inSameDayAs: TextAnalyzer.defaultExpirationDate) {
                    scanResult.expirationDate = date
                    return
                }
            }
        }
    }

    private func extractProductName(from texts: [String], pairs: [String: String]) {
        // 1. 레이블-값 쌍에서 상품명 찾기
        if let productName = pairs["상품명"], !productName.isEmpty {
            scanResult.productName = productName
            return
        }
        
        // 2. 대괄호로 둘러싸인 텍스트 찾기 (예: [스타벅스] 스타벅스 돌체라떼 T)
        let bracketPattern = "\\[([^\\]]+)\\]\\s*(.+)"
        
        for text in texts {
            if let range = text.range(of: bracketPattern, options: .regularExpression) {
                let fullMatch = String(text[range])
                
                do {
                    let regex = try NSRegularExpression(pattern: bracketPattern)
                    let nsString = fullMatch as NSString
                    let results = regex.matches(in: fullMatch, range: NSRange(location: 0, length: nsString.length))
                    
                    if let match = results.first {
                        // 대괄호 안의 내용 (브랜드)
                        if match.numberOfRanges > 1 {
                            let brandRange = match.range(at: 1)
                            let brandName = nsString.substring(with: brandRange)
                            if scanResult.brand.isEmpty {
                                scanResult.brand = brandName
                            }
                        }
                        
                        // 대괄호 뒤의 내용 (상품명)
                        if match.numberOfRanges > 2 {
                            let productRange = match.range(at: 2)
                            scanResult.productName = nsString.substring(with: productRange)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            return
                        }
                    }
                } catch {
                    // 정규식 오류, 다음 방법으로 진행
                }
            }
        }
        
        // 3. 텍스트에서 상품명 찾기 (가장 긴 텍스트부터 시도)
        let potentialProductNames = texts.filter { text in
            // 상품명이 아닐 가능성이 높은 텍스트는 건너뛰기
            !TextAnalyzer.containsPureDatePattern(text) &&
            text.count >= 4 &&
            !TextAnalyzer.isLikelyBarcode(text) &&
            !text.contains("교환처") &&
            !text.contains("주문번호") &&
            !text.contains(scanResult.brand) // 이미 브랜드로 인식된 텍스트는 제외
        }.sorted { $0.count > $1.count }
        
        if let productName = potentialProductNames.first {
            scanResult.productName = productName
        } else {
            scanResult.productName = "상품명 미인식"
        }
    }
    
    // MARK: - 이미지 저장
    
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
            let image = dataScanner.view.asImage()
            parent.didFinishScanning([image])
            dataScanner.dismiss(animated: true)
        }
    }
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
