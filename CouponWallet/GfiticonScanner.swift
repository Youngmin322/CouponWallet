import SwiftUI
import Vision
import VisionKit
import SwiftData


/// 스캔 결과를 처리하기 위한 구조체
struct ScanResult {
    var brand: String = ""
    var productName: String = ""
    var expirationDate: Date = Date().addingTimeInterval(30*24*60*60)
    var imagePath: String = ""
    var imageData: Data? = nil
}


/// 텍스트 분석 관련 상수와 유틸리티 메서드들
struct TextAnalyzer {
    // 날짜 관련 상수
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
    
    /// 바코드인지 확인하는 함수
    static func isBarcode(_ text: String) -> Bool {
        let trimmed = text.replacingOccurrences(of: " ", with: "")
        return trimmed.count >= 8 && trimmed.allSatisfy { $0.isNumber }
    }
    
    /// 바코드일 가능성이 높은지 확인
    static func isLikelyBarcode(_ text: String) -> Bool {
        let justDigits = text.replacingOccurrences(of: " ", with: "")
        
        // 숫자와 공백만 있는지 확인
        let hasOnlyDigitsAndSpaces = text.allSatisfy { $0.isNumber || $0.isWhitespace }
        
        // 총 숫자 길이가 8-16자리인지
        let isWithinBarcodeLength = justDigits.count >= 8 && justDigits.count <= 16
        
        // 4자리씩 나뉘어있는 패턴인지 확인 (예: "7698 8656 3188")
        let hasBarcodePattern = text.contains { $0.isWhitespace } &&
        text.components(separatedBy: .whitespacesAndNewlines)
            .allSatisfy { $0.count == 4 && $0.allSatisfy { $0.isNumber } }
        
        return hasOnlyDigitsAndSpaces && (isWithinBarcodeLength || hasBarcodePattern)
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
    
    /// 문자열에서 날짜 추출 (주 함수)
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
            if let date = dateFormatter.date(from: cleanedText) {
                if date > fiveYearsAgo && date < fiveYearsLater {
                    return date
                }
            }
        }
        
        // 2. 정규식으로 날짜 패턴 추출
        for pattern in datePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let nsString = cleanedText as NSString
                let matches = regex.matches(in: cleanedText, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    let dateSubstring = nsString.substring(with: match.range)
                    let cleanDateSubstring = dateSubstring.replacingOccurrences(of: "까지", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 형식으로 날짜 시도
                    for format in dateFormats {
                        dateFormatter.dateFormat = format
                        if let date = dateFormatter.date(from: cleanDateSubstring) {
                            if date > fiveYearsAgo && date < fiveYearsLater {
                                return date
                            }
                        }
                    }
                    
                    // 년, 월, 일 개별 추출 시도
                    var year: Int?, month: Int?, day: Int?
                    
                    if let yearMatch = try? NSRegularExpression(pattern: yearPattern).firstMatch(
                        in: cleanDateSubstring,
                        range: NSRange(location: 0, length: (cleanDateSubstring as NSString).length)
                    ),
                       let yearRange = Range(yearMatch.range, in: cleanDateSubstring) {
                        let yearStr = cleanDateSubstring[yearRange].replacingOccurrences(of: "년", with: "")
                        year = Int(yearStr)
                    }
                    
                    if let monthMatch = try? NSRegularExpression(pattern: monthPattern).firstMatch(
                        in: cleanDateSubstring,
                        range: NSRange(location: 0, length: (cleanDateSubstring as NSString).length)
                    ),
                       let monthRange = Range(monthMatch.range, in: cleanDateSubstring) {
                        let monthStr = cleanDateSubstring[monthRange].replacingOccurrences(of: "월", with: "")
                        month = Int(monthStr)
                    }
                    
                    if let dayMatch = try? NSRegularExpression(pattern: dayPattern).firstMatch(
                        in: cleanDateSubstring,
                        range: NSRange(location: 0, length: (cleanDateSubstring as NSString).length)
                    ),
                       let dayRange = Range(dayMatch.range, in: cleanDateSubstring) {
                        let dayStr = cleanDateSubstring[dayRange].replacingOccurrences(of: "일", with: "")
                        day = Int(dayStr)
                    }
                    
                    // 년월일로 날짜 생성
                    if let year = year, let month = month, let day = day {
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = day
                        
                        if let date = Calendar.current.date(from: components) {
                            if date > fiveYearsAgo && date < fiveYearsLater {
                                return date
                            }
                        }
                    }
                }
            } catch {
                continue
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
                if let date = dateFormatter.date(from: textWithoutUntil) {
                    if date > fiveYearsAgo && date < fiveYearsLater {
                        return date
                    }
                }
            }
        }
        
        // 기본값 반환
        return Date().addingTimeInterval(30*24*60*60)
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
    
    /// 문자열에서 날짜 패턴 추출
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
}

// MARK: - 기프티콘 스캔 매니저

class GifticonScanManager: ObservableObject {
    @Published var scanResult = ScanResult()
    @Published var isScanning = false
    @Published var showScanResult = false
    
    // 브랜드 키워드 목록
    private let brandKeywords = [
        "스타벅스", "Starbucks", "이디야", "투썸플레이스", "CU", "GS25",
        "세븐일레븐", "배스킨라빈스", "버거킹", "맥도날드", "롯데리아",
        "BBQ", "BHC", "교촌", "네이버페이", "카카오페이", "다이소"
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
    
    // MARK: - 텍스트에서 정보 추출
    
    func extractInformation(from texts: [String]) {
        // 레이블-값 쌍 찾기
        let pairs = TextAnalyzer.findLabelValuePairs(from: texts)
        
        // 추출에 사용할 텍스트 저장 (건너뛸 텍스트 추적)
        var allTexts = texts
        
        // 1. 브랜드 추출
        extractBrand(from: texts, pairs: pairs, allTexts: &allTexts)
        
        // 2. 유효기간 추출
        extractExpirationDate(from: texts, pairs: pairs, allTexts: &allTexts)
        
        // 3. 상품명 추출
        extractProductName(from: texts, pairs: pairs, allTexts: &allTexts)
        
        // 필요한 경우 기본값 설정
        if scanResult.brand.isEmpty {
            scanResult.brand = "기타"
        }
        
        if scanResult.productName.isEmpty {
            let filteredTexts = texts.filter { text in
                !text.contains(scanResult.brand) && text.count > 4 &&
                !TextAnalyzer.containsPureDatePattern(text) && !TextAnalyzer.isBarcode(text)
            }.sorted { $0.count > $1.count }
            
            scanResult.productName = filteredTexts.first ?? "상품명 미인식"
        }
    }
    
    // MARK: - 브랜드 추출
    private func extractBrand(from texts: [String], pairs: [String: String], allTexts: inout [String]) {
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
                    
                    // 이 텍스트는 상품명 고려 대상에서 제외
                    if let index = allTexts.firstIndex(of: text) {
                        allTexts.remove(at: index)
                    }
                    return
                }
            }
        }
    }
    
    // MARK: - 유효기간 추출
    private func extractExpirationDate(from texts: [String], pairs: [String: String], allTexts: inout [String]) {
        // 1. 레이블-값 쌍에서 유효기간 찾기
        if let expiryDate = pairs["유효기간"] ?? pairs["만료일"] ?? pairs["사용기한"], !expiryDate.isEmpty {
            if let date = TextAnalyzer.extractDate(from: expiryDate) {
                scanResult.expirationDate = date
                return
            }
        }
        
        // 2. "까지" 패턴 찾기
        for text in texts {
            if text.contains("까지") || text.hasSuffix("까지") {
                if let date = TextAnalyzer.extractDate(from: text) {
                    // 기본값과 다른지 확인
                    let defaultDate = Date().addingTimeInterval(30*24*60*60)
                    if !Calendar.current.isDate(date, inSameDayAs: defaultDate) {
                        scanResult.expirationDate = date
                        
                        // 이 텍스트는 상품명 고려 대상에서 제외
                        if let index = allTexts.firstIndex(of: text) {
                            allTexts.remove(at: index)
                        }
                        return
                    }
                }
            }
        }
        
        // 3. 순수 날짜 패턴 찾기
        for text in texts {
            if TextAnalyzer.containsPureDatePattern(text) {
                if let date = TextAnalyzer.extractDate(from: text) {
                    // 기본값과 다른지 확인
                    let defaultDate = Date().addingTimeInterval(30*24*60*60)
                    if !Calendar.current.isDate(date, inSameDayAs: defaultDate) {
                        scanResult.expirationDate = date
                        
                        // 이 텍스트는 상품명 고려 대상에서 제외
                        if let index = allTexts.firstIndex(of: text) {
                            allTexts.remove(at: index)
                        }
                        return
                    }
                }
            }
        }
        
        // 4. 일반 텍스트에서 날짜 찾기
        for text in texts {
            if let date = TextAnalyzer.extractDate(from: text) {
                // 기본값과 다른지 확인
                let defaultDate = Date().addingTimeInterval(30*24*60*60)
                if !Calendar.current.isDate(date, inSameDayAs: defaultDate) {
                    scanResult.expirationDate = date
                    
                    // 이 텍스트는 상품명 고려 대상에서 제외
                    if let index = allTexts.firstIndex(of: text) {
                        allTexts.remove(at: index)
                    }
                    return
                }
            }
        }
    }
    
    // MARK: - 상품명 추출
    
    private func extractProductName(from texts: [String], pairs: [String: String], allTexts: inout [String]) {
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
                            let productName = nsString.substring(with: productRange).trimmingCharacters(in: .whitespacesAndNewlines)
                            scanResult.productName = productName
                            
                            // 이 텍스트는 상품명 고려 대상에서 제외
                            if let index = allTexts.firstIndex(of: text) {
                                allTexts.remove(at: index)
                            }
                            return
                        }
                    }
                } catch {
                    // 정규식 오류, 다음 방법으로 진행
                }
            }
        }
        
        // 3. 텍스트에서 상품명 찾기
        let sortedTexts = allTexts.sorted { $0.count > $1.count }
        
        for text in sortedTexts {
            // 상품명이 아닐 가능성이 높은 텍스트는 건너뛰기
            if TextAnalyzer.containsPureDatePattern(text) || text.count < 4 || TextAnalyzer.isBarcode(text) ||
                text.contains("교환처") || text.contains("주문번호") {
                continue
            }
            
            // 좋은 후보를 찾음
            scanResult.productName = text
            return
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

// MARK: - 스캐너 뷰 (iOS 16 이상)

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
            let image = dataScanner.view.asImage()
            parent.didFinishScanning([image])
            dataScanner.dismiss(animated: true)
        }
    }
}

// MARK: - 유틸리티 확장

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
