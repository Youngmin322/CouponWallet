//
//  CaptureManager.swift.swift
//  CouponWallet
//
//  Created by Reimos on 3/9/25.
//

// 스크린 샷을 찍고 앨범에 저장
import SwiftUI
import Photos

// UIView 확장을 통해 해당 뷰를 UIImage로 변환 하는 함수 구현
extension UIView {
    func changeUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
// saveCaptureImageToAlbum - 주어진 스크린샷 이미지를 앨범에 저장
func saveCaptureImageToAlbum(_ screenshot: UIImage) {
    UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
    print("스크린샷 저장 성공!!!")
}

