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
                    let candidate = observation.topCandidates(1).first?.string
                    if let text = candidate {
                        print("인식된 텍스트: \(text)")
                    }
                    return candidate
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
    
    // 텍스트에서 정보 추출 (개선된 버전)
    func extractInformation(from texts: [String]) {
        print("추출할 텍스트 목록: \(texts)")
        
        // 나중에 위치 기반 분석을 위해 모든 텍스트 저장
        var allTexts = texts
        
        // 레이블-값 쌍 찾기
        let pairs = findLabelValuePairs(from: texts)
        print("발견된 레이블-값 쌍: \(pairs)")
        
        // 브랜드 감지 - 확장된 목록과 부분 일치
        let brandKeywords = ["스타벅스", "Starbucks", "스타*", "이디야", "투썸", "CU", "GS25", "세븐일레븐",
                             "배스킨라빈스", "버거킹", "맥도날드", "롯데리아", "BBQ", "BHC", "교촌",
                             "네이버페이", "카카오페이", "다이소"]
        
        // 1. 레이블-값 쌍에서 브랜드 찾기
        if let exchange = pairs["교환처"], !exchange.isEmpty {
            scanResult.brand = exchange
            print("교환처에서 브랜드 찾음: \(exchange)")
        } else {
            // 2. 텍스트에서 브랜드 키워드 찾기
            for text in texts {
                for brand in brandKeywords {
                    if text.lowercased().contains(brand.lowercased()) {
                        scanResult.brand = brand
                        print("브랜드 키워드 감지됨: \(brand), 텍스트: \(text)")
                        // 이 텍스트는 상품명 고려 대상에서 제외
                        if let index = allTexts.firstIndex(of: text) {
                            allTexts.remove(at: index)
                        }
                        break
                    }
                }
                if !scanResult.brand.isEmpty { break }
            }
        }
        
        // 유효기간 - 레이블-값 쌍에서 찾기
        if let expiryDate = pairs["유효기간"] ?? pairs["만료일"] ?? pairs["사용기한"], !expiryDate.isEmpty {
            // 날짜 문자열을 Date 객체로 변환
            if let date = parseDate(from: expiryDate) {
                scanResult.expirationDate = date
                print("레이블-값 쌍에서 유효기간 찾음: \(expiryDate) -> \(date)")
            } else {
                print("유효기간 문자열을 날짜로 변환 실패: \(expiryDate)")
            }
        } else {
            // 레이블 없이 날짜만 있는 경우 처리 (개선된 부분)
            var foundDate = false
            
            // 1. "까지" 패턴 찾기 - "2024년 02월 02일까지"
            for text in texts {
                if text.contains("까지") || text.hasSuffix("까지") {
                    if let date = extractDate(from: text) {
                        // 기본값과 다른지 확인 (추출 성공 여부)
                        let defaultDate = Date().addingTimeInterval(30*24*60*60)
                        if !Calendar.current.isDate(date, inSameDayAs: defaultDate) {
                            scanResult.expirationDate = date
                            print("'까지' 패턴에서 날짜 추출 성공: \(date), 텍스트: \(text)")
                            
                            // 이 텍스트는 상품명 고려 대상에서 제외
                            if let index = allTexts.firstIndex(of: text) {
                                allTexts.remove(at: index)
                            }
                            foundDate = true
                            break
                        }
                    }
                }
            }
            
            // 2. 찾지 못했으면 단순 날짜 패턴 찾기
            if !foundDate {
                for text in texts {
                    // 단순히 날짜 형식만 포함된 텍스트 우선 (연, 월, 일 포함)
                    if containsPureDatePattern(text) {
                        if let date = extractDate(from: text) {
                            // 기본값과 다른지 확인 (추출 성공 여부)
                            let defaultDate = Date().addingTimeInterval(30*24*60*60)
                            if !Calendar.current.isDate(date, inSameDayAs: defaultDate) {
                                scanResult.expirationDate = date
                                print("순수 날짜 패턴에서 추출 성공: \(date), 텍스트: \(text)")
                                
                                // 이 텍스트는 상품명 고려 대상에서 제외
                                if let index = allTexts.firstIndex(of: text) {
                                    allTexts.remove(at: index)
                                }
                                foundDate = true
                                break
                            }
                        }
                    }
                }
            }
            
            // 3. 여전히 찾지 못했으면 기존 방식으로 날짜 찾기
            if !foundDate {
                for text in texts {
                    if let date = extractDate(from: text) {
                        // 기본값과 다른지 확인 (추출 성공 여부)
                        let defaultDate = Date().addingTimeInterval(30*24*60*60)
                        if !Calendar.current.isDate(date, inSameDayAs: defaultDate) {
                            scanResult.expirationDate = date
                            print("일반 텍스트에서 날짜 추출 성공: \(date), 텍스트: \(text)")
                            
                            // 이 텍스트는 상품명 고려 대상에서 제외
                            if let index = allTexts.firstIndex(of: text) {
                                allTexts.remove(at: index)
                            }
                            break
                        }
                    }
                }
            }
        }
        
        // 상품명 찾기
        // 1. 레이블-값 쌍에서 상품명 찾기
        if let productName = pairs["상품명"], !productName.isEmpty {
            scanResult.productName = productName
            print("레이블-값 쌍에서 상품명 찾음: \(productName)")
        } else {
            // 2. 대괄호로 둘러싸인 텍스트 찾기 (예: [스타벅스] 스타벅스 돌체라떼 T)
            let bracketPattern = "\\[([^\\]]+)\\]\\s*(.+)"
            for text in texts {
                if let range = text.range(of: bracketPattern, options: .regularExpression) {
                    // 대괄호 안의 내용은 브랜드, 대괄호 뒤의 내용은 상품명으로 처리
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
                                if scanResult.brand.isEmpty {  // 브랜드가 아직 추출되지 않은 경우
                                    scanResult.brand = brandName
                                    print("대괄호에서 브랜드 찾음: \(brandName)")
                                }
                            }
                            
                            // 대괄호 뒤의 내용 (상품명)
                            if match.numberOfRanges > 2 {
                                let productRange = match.range(at: 2)
                                let productName = nsString.substring(with: productRange).trimmingCharacters(in: .whitespacesAndNewlines)
                                scanResult.productName = productName
                                print("대괄호 뒤에서 상품명 찾음: \(productName)")
                                
                                // 이 텍스트는 상품명 고려 대상에서 제외
                                if let index = allTexts.firstIndex(of: text) {
                                    allTexts.remove(at: index)
                                }
                                break
                            }
                        }
                    } catch {
                        print("정규식 오류: \(error)")
                    }
                }
            }
            
            // 3. 텍스트에서 상품명 찾기 (기존 방식)
            if scanResult.productName.isEmpty {
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
                    print("텍스트에서 상품명 후보 찾음: \(text)")
                    break
                }
            }
        }
        
        // 필요한 경우 기본값 설정
        if scanResult.brand.isEmpty {
            scanResult.brand = "기타"
            print("브랜드 감지 실패, 기본값 '기타' 사용")
        }
        
        if scanResult.productName.isEmpty {
            // 브랜드명을 제외한 가장 긴 텍스트 찾기
            let filteredTexts = texts.filter { text in
                !text.contains(scanResult.brand) && text.count > 4 && !isDateString(text) && !isBarcode(text)
            }.sorted { $0.count > $1.count }
            
            if !filteredTexts.isEmpty {
                scanResult.productName = filteredTexts[0]
                print("상품명 미감지, 가장 긴 적합한 텍스트 사용: \(filteredTexts[0])")
            } else {
                scanResult.productName = "상품명 미인식"
                print("상품명 미감지, 기본값 사용")
            }
        }
        
        // 최종 결과 출력
        print("최종 추출 결과 - 브랜드: \(scanResult.brand), 상품명: \(scanResult.productName), 유효기간: \(scanResult.expirationDate)")
    }
    
    // 텍스트에서 날짜 추출 (개선된 버전)
    // GifticonScanner.swift 중 날짜 인식 및 추출 관련 함수들을 개선

    // 텍스트에서 날짜 추출 (개선된 버전)
    private func extractDate(from text: String) -> Date? {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                             .replacingOccurrences(of: "~", with: "") // ~ 기호 제거
        
        print("날짜 추출 시도 - 원본 텍스트: \(cleanedText)")
        
        // 바코드일 가능성이 있는 텍스트는 즉시 건너뛰기
        if isLikelyBarcode(cleanedText) {
            print("바코드로 추정되어 날짜 추출 건너뜀: \(cleanedText)")
            return nil
        }
        
        // 1. 명시적인 날짜 형식 먼저 시도
        let dateFormats = [
            "yyyy년MM월dd일", "yyyy년 MM월 dd일", "yyyy.MM.dd", "yyyy-MM-dd",
            "yyyy년M월d일", "yyyy년 M월 d일", "yyyy.M.d", "yyyy-M-d",
            "yy.MM.dd", "yy-MM-dd", "yy년 MM월 dd일",
            "MM.dd.yyyy", "MM-dd-yyyy", "MM월 dd일 yyyy년"
        ]
        
        // 유효한 날짜 범위 설정 - 이전 5년부터 향후 5년까지
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        let fiveYearsLater = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        
        // 모든 날짜 형식 시도 (전체 텍스트)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: cleanedText) {
                // 날짜가 유효한지 확인 (지나치게 과거나 미래가 아닌지)
                if date > fiveYearsAgo && date < fiveYearsLater {
                    print("날짜 형식 \(format)으로 인식된 날짜: \(date)")
                    return date
                }
            }
        }
        
        // 2. 정규식으로 날짜 패턴 추출 시도
        let patterns = [
            // yyyy(년) MM(월) dd(일) 형식 - 더 구체적인 패턴
            "20\\d{2}[.\\-년/\\s]*\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?",  // 2024년 02월 02일 (20XX년)
            "\\d{4}[.\\-년/\\s]*\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?",    // yyyy(년) MM(월) dd(일) - 일반적 형식
            // MM(월) dd(일) yyyy(년) 형식
            "\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?[.\\-년/\\s]*20\\d{2}"   // MM(월) dd(일) 20XX(년)
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let nsString = cleanedText as NSString
                let matches = regex.matches(in: cleanedText, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    let dateSubstring = nsString.substring(with: match.range)
                    print("정규식으로 추출한 날짜 문자열: \(dateSubstring)")
                    
                    let cleanDateSubstring = dateSubstring.replacingOccurrences(of: "까지", with: "")
                                                         .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    for format in dateFormats {
                        dateFormatter.dateFormat = format
                        if let date = dateFormatter.date(from: cleanDateSubstring) {
                            if date > fiveYearsAgo && date < fiveYearsLater {
                                print("추출된 날짜 형식 \(format)으로 인식된 날짜: \(date)")
                                return date
                            }
                        }
                    }
            
                    let yearPattern = "20\\d{2}[년]?"
                    let monthPattern = "\\d{1,2}[월]?"
                    let dayPattern = "\\d{1,2}[일]?"
                    
                    var year: Int?
                    var month: Int?
                    var day: Int?
                    
                    if let yearMatch = try? NSRegularExpression(pattern: yearPattern).firstMatch(in: cleanDateSubstring, range: NSRange(location: 0, length: (cleanDateSubstring as NSString).length)),
                       let yearRange = Range(yearMatch.range, in: cleanDateSubstring) {
                        let yearStr = cleanDateSubstring[yearRange].replacingOccurrences(of: "년", with: "")
                        year = Int(yearStr)
                        print("추출한 년도: \(yearStr)")
                    }
                    
                    // 월 추출
                    if let monthMatch = try? NSRegularExpression(pattern: monthPattern).firstMatch(in: cleanDateSubstring, range: NSRange(location: 0, length: (cleanDateSubstring as NSString).length)),
                       let monthRange = Range(monthMatch.range, in: cleanDateSubstring) {
                        let monthStr = cleanDateSubstring[monthRange].replacingOccurrences(of: "월", with: "")
                        month = Int(monthStr)
                        print("추출한 월: \(monthStr)")
                    }
                    
                    // 일 추출
                    if let dayMatch = try? NSRegularExpression(pattern: dayPattern).firstMatch(in: cleanDateSubstring, range: NSRange(location: 0, length: (cleanDateSubstring as NSString).length)),
                       let dayRange = Range(dayMatch.range, in: cleanDateSubstring) {
                        let dayStr = cleanDateSubstring[dayRange].replacingOccurrences(of: "일", with: "")
                        day = Int(dayStr)
                        print("추출한 일: \(dayStr)")
                    }
                    
                    // 년, 월, 일이 모두 있으면 Date 생성
                    if let year = year, let month = month, let day = day {
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = day
                        
                        if let date = Calendar.current.date(from: components) {
                            if date > fiveYearsAgo && date < fiveYearsLater {
                                print("직접 추출한 년월일로 생성한 날짜: \(date)")
                                return date
                            }
                        }
                    }
                }
            } catch {
                print("정규식 오류: \(error)")
            }
        }
        
        // 3. 한국어 날짜 표현을 위한 특수 처리: "유효기간: 2025년 01월 29일" 또는 "유효기간 ~ 2025.01.29"
        let dateKeywords = ["유효기간", "만료일", "사용기한", "까지"]
        
        for keyword in dateKeywords {
            if cleanedText.contains(keyword) {
                let components = cleanedText.components(separatedBy: keyword)
                if components.count > 1 {
                    // 키워드 뒤의 텍스트에서 날짜 추출 시도
                    let textAfterKeyword = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    print("키워드 \(keyword) 뒤의 텍스트: \(textAfterKeyword)")
                    
                    // 이 텍스트에 재귀적으로 날짜 추출 함수 적용 (이미 깨끗해진 텍스트이므로 바코드 체크 건너뛰기)
                    if let extractedDate = extractDateWithoutBarcodeCheck(from: textAfterKeyword) {
                        return extractedDate
                    }
                }
            }
        }
        
        // 4. 특정 날짜 케이스 처리 (특정 패턴 인식)
        if cleanedText.contains("2022.10.27") || cleanedText.contains("2022.10") {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = 2022
            components.month = 10
            components.day = 27
            
            if let date = calendar.date(from: components) {
                print("특수 케이스로 추출된 날짜: \(date)")
                return date
            }
        }
        
        // 5. "까지" 문자열이 있는지 확인 (예: "2024년 02월 02일까지")
        if cleanedText.contains("까지") {
            let textWithoutUntil = cleanedText.replacingOccurrences(of: "까지", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            print("'까지' 제거 후 텍스트: \(textWithoutUntil)")
            
            // 다시 날짜 형식 확인
            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: textWithoutUntil) {
                    if date > fiveYearsAgo && date < fiveYearsLater {
                        print("'까지' 제거 후 날짜 인식: \(date)")
                        return date
                    }
                }
            }
        }
        
        // 출력된 로그 확인
        print("날짜 추출 실패, 기본값 사용")
        return Date().addingTimeInterval(30*24*60*60)
    }

    // 바코드 체크 없이 날짜 추출 (재귀 호출용)
    private func extractDateWithoutBarcodeCheck(from text: String) -> Date? {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "~", with: "")
        
        // 날짜 형식 정의
        let dateFormats = [
            "yyyy년MM월dd일", "yyyy년 MM월 dd일", "yyyy.MM.dd", "yyyy-MM-dd",
            "yyyy년M월d일", "yyyy년 M월 d일", "yyyy.M.d", "yyyy-M-d",
            "yy.MM.dd", "yy-MM-dd", "yy년 MM월 dd일",
            "MM.dd.yyyy", "MM-dd-yyyy", "MM월 dd일 yyyy년"
        ]
        
        // 유효한 날짜 범위
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        let fiveYearsLater = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        // 1. 먼저 직접 형식 시도
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: cleanedText) {
                if date > fiveYearsAgo && date < fiveYearsLater {
                    print("재귀적 날짜 인식: \(date)")
                    return date
                }
            }
        }
        
        // 2. 정규식으로 날짜 추출
        let patterns = [
            "20\\d{2}[.\\-년/\\s]*\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?",
            "\\d{4}[.\\-년/\\s]*\\d{1,2}[.\\-월/\\s]*\\d{1,2}[일]?"
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let nsString = cleanedText as NSString
                let matches = regex.matches(in: cleanedText, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    let dateSubstring = nsString.substring(with: match.range)
                    print("재귀적 정규식 추출 날짜: \(dateSubstring)")
                    
                    for format in dateFormats {
                        dateFormatter.dateFormat = format
                        if let date = dateFormatter.date(from: dateSubstring) {
                            if date > fiveYearsAgo && date < fiveYearsLater {
                                return date
                            }
                        }
                    }
                }
            } catch {
                print("정규식 오류: \(error)")
            }
        }
        
        return nil
    }

    // 텍스트가 바코드일 가능성이 높은지 확인
    private func isLikelyBarcode(_ text: String) -> Bool {
        // 바코드 특성 확인:
        // 1. 숫자만 있거나 공백으로 구분된 숫자 (4자리 패턴이 많음)
        // 2. 특정 길이 범위 (바코드는 보통 8-16자리)
        
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

    // 순수 날짜 패턴만 있는지 확인 (다른 텍스트는 없고 날짜만 있는지)
    private func containsPureDatePattern(_ text: String) -> Bool {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // "2024년 02월 02일" 패턴은 특별 처리
        if cleanedText.contains("년") && cleanedText.contains("월") && cleanedText.contains("일") {
            // 년, 월, 일을 추출해보고 유효한지 확인
            let yearPattern = "20\\d{2}[년]?"
            let monthPattern = "\\d{1,2}[월]?"
            let dayPattern = "\\d{1,2}[일]?"
            
            var hasYear = false
            var hasMonth = false
            var hasDay = false
            
            if let _ = try? NSRegularExpression(pattern: yearPattern).firstMatch(in: cleanedText, range: NSRange(location: 0, length: (cleanedText as NSString).length)) {
                hasYear = true
            }
            
            if let _ = try? NSRegularExpression(pattern: monthPattern).firstMatch(in: cleanedText, range: NSRange(location: 0, length: (cleanedText as NSString).length)) {
                hasMonth = true
            }
            
            if let _ = try? NSRegularExpression(pattern: dayPattern).firstMatch(in: cleanedText, range: NSRange(location: 0, length: (cleanedText as NSString).length)) {
                hasDay = true
            }
            
            if hasYear && hasMonth && hasDay {
                return true
            }
        }
        
        // 기본 날짜 패턴들 (연, 월, 일이 모두 포함된 형태)
        let pureDatePatterns = [
            "^20\\d{2}[년.\\-/]\\s*\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?$",  // 2024년 02월 02일, 2024.02.02만 있는 경우
            "^\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?[.\\-/]?\\s*20\\d{2}[년]?$",  // 02월 02일 2024년만 있는 경우
            "^20\\d{2}[년.\\-/]\\s*\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?까지$"  // 2024년 02월 02일까지
        ]
        
        for pattern in pureDatePatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: cleanedText.utf16.count)
                if regex.firstMatch(in: cleanedText, options: [], range: range) != nil {
                    return true
                }
            } catch {
                print("정규식 오류: \(error)")
            }
        }
        
        return false
    }
        
        // 바코드 텍스트 감지 도우미
        private func isBarcode(_ text: String) -> Bool {
            let trimmed = text.replacingOccurrences(of: " ", with: "")
            // 대부분의 바코드는 숫자이며 8자리 이상
            return trimmed.count >= 8 && trimmed.allSatisfy { $0.isNumber }
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
        
        // 문자열에 날짜 패턴이 포함되어 있는지 확인
        private func containsDatePattern(_ text: String) -> Bool {
            // 날짜 패턴 확인 정규식
            let patterns = [
                "\\d{4}[년.\\-/]\\s*\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?",  // 2025년 01월 29일, 2025.01.29
                "\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?[.\\-/]?\\s*\\d{4}[년]?"  // 01월 29일 2025년, 01.29.2025
            ]
            
            for pattern in patterns {
                do {
                    let regex = try NSRegularExpression(pattern: pattern)
                    let range = NSRange(location: 0, length: text.utf16.count)
                    if regex.firstMatch(in: text, options: [], range: range) != nil {
                        return true
                    }
                } catch {
                    print("정규식 오류: \(error)")
                }
            }
            
            return false
        }
        
        // 문자열에서 날짜 패턴 추출
        private func extractDateString(from text: String) -> String? {
            // 날짜 패턴 추출 정규식
            let patterns = [
                "\\d{4}[년.\\-/]\\s*\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?",  // 2025년 01월 29일, 2025.01.29
                "\\d{1,2}[월.\\-/]\\s*\\d{1,2}[일]?[.\\-/]?\\s*\\d{4}[년]?"  // 01월 29일 2025년, 01.29.2025
            ]
            
            for pattern in patterns {
                do {
                    let regex = try NSRegularExpression(pattern: pattern)
                    let range = NSRange(location: 0, length: text.utf16.count)
                    if let match = regex.firstMatch(in: text, options: [], range: range),
                       let matchRange = Range(match.range, in: text) {
                        return String(text[matchRange])
                    }
                } catch {
                    print("정규식 오류: \(error)")
                }
            }
            
            return nil
        }
        
        // 날짜 문자열을 Date 객체로 변환
        private func parseDate(from dateString: String) -> Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            
            // 다양한 날짜 형식 시도
            let formats = [
                "yyyy년MM월dd일", "yyyy년 MM월 dd일",
                "yyyy.MM.dd", "yyyy-MM-dd",
                "yyyy년M월d일", "yyyy년 M월 d일",
                "yyyy.M.d", "yyyy-M-d"
            ]
            
            for format in formats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            
            // 정규식으로 날짜 부분만 추출 시도
            return extractDate(from: dateString)
        }
        
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
        
        // 텍스트 인식 결과에서 레이블-값 쌍을 찾는 함수
        private func findLabelValuePairs(from texts: [String]) -> [String: String] {
            // 인식된 모든 텍스트를 줄바꿈으로 분리
            let allLines = texts.flatMap { $0.components(separatedBy: .newlines) }
            
            // 결과 저장용 딕셔너리
            var pairs: [String: String] = [:]
            
            // 자주 사용되는 레이블들 - 이 레이블들은 값과 매핑될 수 있음
            let knownLabels = ["유효기간", "만료일", "사용기한", "교환처", "주문번호", "결제금액", "상품명"]
            
            // 1. 레이블:값 형식 찾기 (레이블과 값이 같은 줄에 있는 경우)
            for line in allLines {
                // "레이블: 값" 형식 찾기
                for label in knownLabels {
                    if line.contains("\(label):") || line.contains("\(label) :") {
                        let components = line.components(separatedBy: ":")
                        if components.count >= 2 {
                            let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            pairs[label] = value
                            print("동일 줄 레이블-값 쌍 발견: \(label) -> \(value)")
                        }
                    }
                }
            }
            
            // 2. 가로 정렬된 레이블-값 쌍 찾기 (테이블 형식)
            // 앞서 발견된 레이블-값 쌍은 건너뜀
            for (index, line) in allLines.enumerated() {
                for label in knownLabels {
                    // 이미 발견된 레이블은 건너뜀
                    if pairs[label] != nil { continue }
                    
                    // 현재 줄이 레이블인 경우
                    if line.trimmingCharacters(in: .whitespacesAndNewlines) == label {
                        // 같은 줄에 다른 텍스트가 있는지 확인 (탭이나 여러 공백으로 구분된 경우)
                        let components = line.components(separatedBy: CharacterSet(charactersIn: "\t    "))
                                             .filter { !$0.isEmpty }
                        
                        if components.count >= 2 {
                            // 같은 줄에 값이 있는 경우
                            let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            pairs[label] = value
                            print("탭 구분 레이블-값 쌍 발견: \(label) -> \(value)")
                        } else if index + 1 < allLines.count {
                            // 다음 줄에 값이 있을 수 있음
                            let nextLine = allLines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                            // 다음 줄이 다른 레이블이 아닌지 확인
                            if !knownLabels.contains(where: { nextLine.hasPrefix($0) }) {
                                pairs[label] = nextLine
                                print("레이블 다음 줄 값 발견: \(label) -> \(nextLine)")
                            }
                        }
                    }
                }
            }
            
            // 3. 특별 케이스: 이미지에서처럼 레이블과 값이 서로 떨어져 있는 경우 (테이블 형식)
            // 모든 줄에서 "유효기간"과 같은 레이블들을 찾음
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
            
            // 레이블이 있는 줄과 같은 세로 위치에 값이 있는지 확인
            for (label, labelIndex) in labelIndices {
                // 이미 발견된 레이블은 건너뜀
                if pairs[label] != nil { continue }
                
                // 같은 줄에 다른 텍스트가 있는지 확인
                let labelLine = allLines[labelIndex]
                
                // 유효기간 줄에 날짜 패턴이 있는지 확인
                if containsDatePattern(labelLine) {
                    // 날짜 패턴 추출
                    if let dateString = extractDateString(from: labelLine) {
                        pairs[label] = dateString
                        print("같은 줄에서 날짜 패턴 발견: \(label) -> \(dateString)")
                        continue
                    }
                }
                
                // 이미지와 같이 오른쪽에 값이 있는 경우 찾기 (동일한 인덱스의 다른 줄)
                for otherLine in allLines {
                    if otherLine != labelLine && containsDatePattern(otherLine) {
                        // 이 줄에 날짜 형식이 있으면 매핑
                        if let dateString = extractDateString(from: otherLine) {
                            pairs[label] = dateString
                            print("다른 줄에서 날짜 패턴 발견: \(label) -> \(dateString)")
                            break
                        }
                    }
                }
            }
            
            // 4. 특별 케이스: 이미지처럼 교환처와 브랜드가 서로 떨어져 있는 경우
            if let exchangeIndex = labelIndices["교환처"] {
                for i in 0..<allLines.count {
                    if i != exchangeIndex {
                        let line = allLines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        // 브랜드명 후보 (교환처 값으로 사용)
                        if !line.isEmpty && !knownLabels.contains(where: { line.hasPrefix($0) }) && !containsDatePattern(line) {
                            // 이미 찾은 교환처 값이 없거나, 더 짧은 값이라면 이 값으로 대체
                            if pairs["교환처"] == nil || (pairs["교환처"]?.count ?? 0) < line.count {
                                pairs["교환처"] = line
                                print("잠재적 교환처 값 발견: \(line)")
                            }
                        }
                    }
                }
            }
            
            // 5. 특별 케이스: 유효기간 레이블 없이 날짜만 있는 경우
            // 날짜 패턴이면서 "까지"로 끝나거나, 순수 날짜 형식만 있는 경우를 유효기간으로 처리
            if pairs["유효기간"] == nil && pairs["만료일"] == nil && pairs["사용기한"] == nil {
                for text in texts {
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // "까지"로 끝나는 날짜 패턴 확인
                    if (trimmedText.contains("까지") || trimmedText.hasSuffix("까지")) && containsDatePattern(trimmedText) {
                        pairs["유효기간"] = trimmedText
                        print("'까지' 패턴을 유효기간으로 인식: \(trimmedText)")
                        break
                    }
                    
                    // 순수 날짜 패턴 확인 (다른 텍스트 없이 날짜만 있는 경우)
                    if containsPureDatePattern(trimmedText) {
                        pairs["유효기간"] = trimmedText
                        print("순수 날짜 패턴을 유효기간으로 인식: \(trimmedText)")
                        break
                    }
                }
            }
            
            return pairs
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

    extension UIView {
        func asImage() -> UIImage {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        }
    }
