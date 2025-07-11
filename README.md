# CouponWallet  
![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift)
![Platform](https://img.shields.io/badge/Platforms-iOS%2018.0+-007AFF?logo=apple)

CouponWallet은 디지털 기프티콘을 관리하기 위한 종합적인 iOS 애플리케이션입니다. 이 앱을 통해 사용자는 디지털 쿠폰을 스캔하고, 저장하고, 정리하며, 한 곳에서 편리하게 관리할 수 있습니다.

## 개요

- 프로젝트 이름: CouponWallet
- 프로젝트 기간: 3월 7일 ~ 3월 11일
- 개발 언어: Swift
- 개발 프레임워크: SwiftUI, PhotosUI, Vision, VisionKit, SwiftData
- 멤버: 김대홍, 조영민, 홍석평

## 🌟 주요 기능
### 홈 탭
- **보유 쿠폰 보기**: 사용 가능한 유효한 쿠폰을 한눈에 볼 수 있습니다
- **쿠폰 필터링**: 브랜드별로 쉽게 필터링 가능 (스타벅스, 치킨, CU, GS25 등)
- **쿠폰 추가**: 다음 방법으로 새 기프티콘을 추가할 수 있습니다:
  - 카메라 직접 스캔(구현 중...)
  - 사진 갤러리에서 가져오기
### 사용·만료 탭
- **사용/만료된 쿠폰 보기**: 사용 이력을 추적할 수 있습니다
- **필터 옵션**: "사용 완료" 또는 "만료" 상태별로 정렬
- **다중 선택**: 여러 쿠폰을 선택하여 휴지통으로 이동
- **정렬**: 날짜별 정렬 (최신순/오래된 순)
### 설정 탭
- **프로필 설정**: 사용자 프로필 정보 관리
- **알림 설정**: 앱 알림 구성
- **테마 설정**: 라이트 모드와 다크 모드 전환
- **휴지통 관리**: 쿠폰 복구 또는 영구 삭제
## 📱 핵심 기능
### 쿠폰 이미지 스캐닝
Vision 및 VisionKit 프레임워크를 사용하여:
- 기프티콘 이미지에서 텍스트를 자동으로 인식
- 다음과 같은 주요 정보 추출:
  - 브랜드명
  - 상품명
  - 유효기간
- 카메라 스캔과 갤러리 이미지 모두 처리
  
### 직관적인 UI
- 스와이프 가능한 쿠폰 상세 정보
- 탭 기반 네비게이션
- 쿠폰 상태에 따른 컨텍스트 액션

### SwiftData를 사용한 데이터 관리
- 쿠폰 정보의 영구 저장
- 복원 옵션이 있는 휴지통 기능

## 🔧 기술적 구현
### 사용된 프레임워크
- **SwiftData**: 데이터 영속성 레이어
- **Vision/VisionKit**: OCR 및 텍스트 인식
- **PhotosUI**: 사진 라이브러리 통합
  
### 주요 구성 요소
- **GifticonScanManager**: OCR 및 텍스트 추출 처리
- **TextAnalyzer**: 스캔된 텍스트에서 의미 있는 데이터 파싱 및 추출
- **Gifticon Model**: 쿠폰 정보 저장을 위한 SwiftData 모델
- **사용자 정의 뷰**: 다양한 쿠폰 상태 및 작업을 위한 특수 뷰
  
### 사용자 경험 기능
- 쿠폰 공유를 위한 쿠폰 이미지 공유 기능
- 쿠폰 카드 애니메이션 전환 효과
- 앨범에 있는 쿠폰 자동 스캔 및 이미지 추가
  
## 📷 스크린샷
<p align="center">
  <img src="https://github.com/user-attachments/assets/8227419b-acc9-4d09-bd8e-f984d44caf57" width="18%" alt="홈 화면" />
  <img src="https://github.com/user-attachments/assets/a5f0a14f-c17f-4cc5-94ca-bcf3648cb1db" width="18%" alt="상세 화면" />
  <img src="https://github.com/user-attachments/assets/6a3bb6c2-3338-49a8-a477-66631edae118" width="18%" alt="설정 화면" />
  <img src="https://github.com/user-attachments/assets/45043c37-2600-4c86-ba5b-d154bf16db15" width="18%" alt="만료 화면" />
  <img src="https://github.com/user-attachments/assets/9a48daca-54cd-4295-bfd0-6ceea373557b" width="18%" alt="스캔 화면" />
</p>

## 📝 피그마 설계도
<img width="1053" alt="스크린샷 2025-03-11 오후 2 44 05" src="https://github.com/user-attachments/assets/38c48f01-3ecd-4dcf-9acb-a0492f907d16" />


## 🚀 시작하기
### 요구 사항
- iOS 18.0+
- Xcode 16.0+
- Swift 5.0+
  
## 🔮 향후 개선 사항
- 바코드/QR 코드 스캐닝
- 유효기간 알림
- 인기 브랜드 API와의 통합
- 소셜 공유 기능
- 통계 및 사용 분석

## 👥 역할

### 김대홍
- 쿠폰 선택 화면
- 쿠폰 카드 슬라이드 애니메이션
- 쿠폰 사용 완료 및 수정 로직 구현

### 조영민
- 기본 틀 프로젝트 제작
- PhotoPicker로 이미지 가져오기
- vision 프레임워크로 쿠폰 이미지 스캔 기능 구현

### 홍석평
- 쿠폰 공유 기능
- 쿠폰 삭제 기능
- 라이트 모드 다크 모드 구현

## 느낀 점과 개선할 점

### 김대홍
- 사용가능 쿠폰 선택 화면: 더미 데이터에서 실행되던 코드가, 더미 데이터 없이 Merge 작업하니 에러가 발생되는 문제를 해결하는 단계에서 어려움을 겪었습니다.
- 사용완료 및 기간만료 쿠폰 선택 화면: 2개의 탭 뷰를 동시에 연결되는 화면을 만들려다 보니 어려움을 느껴, 사용가능 쿠폰과 사용완료/기간만료 쿠폰 선택을 화면을 분할하였습니다.
- 쿠폰을 좌우로 슬라이드 뷰를 구성하면서, 정렬순서를 탭 뷰의 정렬순서대로 구현하는 것이 쉽지 않았습니다.
- 화면 기준으로 업무를 분배하다보니 연결되는 화면이 있을 경우, 협업이 필요함을 알았습니다.
- Github: 처음 설정할 때, .gitignore 만들어서인지, 코드 외 충돌 문제가 없어서 원활하게 진행할 수 있지 않았나 싶습니다.

### 조영민
- **Vision 스캔 기능**: 이미지 스캔 처리 기능을 처음 구현해보았는데 생각보다 고려해야 할 것이 많고 이미지 인식이 잘 안 되어서 조금 더 세부적으로 공부한 다음 인식률을 올려보고 싶다는 생각이 들었습니다.
- **뷰 나누기의 중요성**: 뷰를 세부적으로 나눠야 유지보수 측면에서도 편하고 유지보수가 아니더라도 초기 개발 과정에서도 중요하다는 것을 느꼈습니다. 특히 이 부분에서 재사용성과 가독성이 크게 향상될 수 있다는 것을 느꼈습니다.
- **깃의 중요성**: 깃을 제대로 알아야 어느 부분에서 충돌이 생긴 건지 알고 빠르게 해결해야 개발 시간도 확보되고 낭비되는 시간을 줄일 수 있다는 것을 느껴서 깃을 제대로 알고 써야겠다는 생각을 했습니다.

### 홍석평
- **구현**: 선택한 쿠폰을 캡처하고 공유할 때 ShareLink를 활용하여 다양한 앱으로 쉽게 공유하도록 만들었습니다. 또한, 다크 모드 전환 기능을 구현하여 사용자 환경에 맞는 UI를 지원하도록 했습니다. 쿠폰 삭제의 복원 기능을 구현하는 과정에서 어려움을 겪었습니다.
- 예상치 못한 문제를 해결하는 과정에서 많은 것을 배울 수 있었으며, 이를 통해 더욱 견고한 기능을 구현하는 방법을 익히게 되었습니다.
- **Git**: 팀원들과 Git을 활용한 협업을 진행하며 부족한 부분을 깨닫게 되었습니다.
자주 사용하면서 익숙해지기 위해 학습을 지속하고 있으며, 실전 경험을 통해 보다 효과적인 Git 활용법을 익히고 있습니다.
