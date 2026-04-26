import SwiftUI
import UIKit

// 시스템 공유 시트(UIActivityViewController)를 띄우는 헬퍼
// ImageRenderer 로 캡처한 이미지/메시지를 카카오톡, 인스타그램 등 외부 앱으로 공유할 때 사용
@MainActor
func presentShareSheet(items: [Any]) {
    // 활성화된 윈도우 씬 찾기
    guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let rootVC = windowScene.windows.first?.rootViewController else {
        return
    }

    let activityVC = UIActivityViewController(
        activityItems: items,
        applicationActivities: nil
    )

    // iPad 지원 (popover 앵커 설정)
    let window = windowScene.windows.first
    activityVC.popoverPresentationController?.sourceView = window
    activityVC.popoverPresentationController?.sourceRect = CGRect(
        x: (window?.bounds.midX ?? 0),
        y: (window?.bounds.midY ?? 0),
        width: 0,
        height: 0
    )

    // 가장 위쪽 ViewController 위에 present
    var topVC = rootVC
    while let presented = topVC.presentedViewController {
        topVC = presented
    }
    topVC.present(activityVC, animated: true)
}
