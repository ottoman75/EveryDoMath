---
name: feature-share
description: "EveryDoMath 앱에 게임 결과 카드 공유 기능을 구현. ImageRenderer로 공유 카드 생성, UIActivityViewController로 카카오/인스타 공유. 기능3 구현 또는 feature-share 에이전트 실행 시 반드시 이 스킬을 사용."
---

# Feature Share — 결과 카드 공유

## 프로젝트 컨텍스트

- **경로:** `/Users/otto/DevWork/EveryDoMath/EveryDoMath/`
- **수정 대상:** `Presentation/Result/ResultView.swift`, `Presentation/Result/ResultViewModel.swift`
- **iOS 26+:** `ImageRenderer`는 `@MainActor` 필수, `UIScreen.main.scale` 사용 가능
- **기존 색상:** `Color.appPrimaryStart`, `Color.appPrimaryEnd`, `Color.appCard`, `Color.appText`, `Color.appSubtext`, `Color.appWarning`, `Color.appSuccess`, `Color.appDanger`

## ShareCardView.swift

```swift
import SwiftUI

struct ShareCardView: View {
    let session: GameSession
    let grade: GameGrade
    let nickname: String

    var body: some View {
        ZStack {
            // 배경 그라데이션 (등급별)
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // 상단 브랜딩
                HStack {
                    Image(systemName: "sum")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("EveryDoMath")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer()

                // 등급 배지
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 3)
                        .frame(width: 100, height: 100)
                    Text(grade.rawValue)
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                // 점수
                Text("\(session.score)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 12)

                Text("점")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                // 하단 통계
                HStack(spacing: 0) {
                    statItem(value: "\(session.correctCount)/\(GameSession.problemCount)", label: "정답")
                    Divider().frame(height: 36).background(.white.opacity(0.3))
                    statItem(value: String(format: "%.1f초", session.timeTaken), label: "시간")
                    Divider().frame(height: 36).background(.white.opacity(0.3))
                    statItem(value: session.grade.label, label: "학년")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(.white.opacity(0.1))

                // 닉네임 + 태그
                HStack {
                    Text("@\(nickname)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("#수학왕 #EveryDoMath")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 360, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var gradientColors: [Color] {
        switch grade {
        case .S: return [Color(red: 1.0, green: 0.75, blue: 0.0), Color(red: 1.0, green: 0.45, blue: 0.0)]
        case .A: return [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.0, green: 0.55, blue: 0.3)]
        case .B: return [Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.35, blue: 0.85)]
        case .C: return [Color(red: 0.6, green: 0.6, blue: 0.7), Color(red: 0.4, green: 0.4, blue: 0.5)]
        case .D: return [Color(red: 0.9, green: 0.35, blue: 0.35), Color(red: 0.7, green: 0.15, blue: 0.15)]
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
}
```

## View+ShareSheet.swift

```swift
import SwiftUI
import UIKit

extension View {
    @MainActor
    func presentShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // iPad 지원
        activityVC.popoverPresentationController?.sourceView = windowScene.windows.first
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)

        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        topVC.present(activityVC, animated: true)
    }
}
```

## ResultViewModel 수정

기존 `ResultViewModel`에 추가:
```swift
@MainActor
func shareResult(nickname: String) {
    let card = ShareCardView(session: session, grade: gameGrade, nickname: nickname)
    let renderer = ImageRenderer(content: card)
    renderer.scale = 3.0  // 고해상도
    guard let image = renderer.uiImage else { return }

    let message = "EveryDoMath에서 \(gameGrade.rawValue)등급 달성! 🎉 \(session.score)점 획득했어요!"
    UIView().presentShareSheet(items: [image, message])
}
```

`UIView().presentShareSheet(...)` 대신 `View+ShareSheet.swift`의 `presentShareSheet`를 호출.
실제로는 `@Environment` 혹은 `UIApplication.shared`를 통해 호출.

수정된 호출 방식:
```swift
// ResultViewModel.swift
@MainActor
func shareResult(nickname: String) {
    let card = ShareCardView(session: session, grade: gameGrade, nickname: nickname)
    let renderer = ImageRenderer(content: card)
    renderer.scale = 3.0
    guard let image = renderer.uiImage else { return }
    let message = "EveryDoMath에서 \(gameGrade.rawValue)등급 달성! 🎉 \(session.score)점!"
    
    guard let windowScene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let rootVC = windowScene.windows.first?.rootViewController else { return }
    
    let activityVC = UIActivityViewController(activityItems: [image, message], applicationActivities: nil)
    activityVC.popoverPresentationController?.sourceView = windowScene.windows.first
    var topVC = rootVC
    while let presented = topVC.presentedViewController { topVC = presented }
    topVC.present(activityVC, animated: true)
}
```

## ResultView 수정

`actionButtons`의 맨 위에 공유 버튼 추가:
```swift
// 공유 버튼 (맨 위)
Button {
    let nickname = appState.profile?.nickname ?? "수학왕"
    viewModel.shareResult(nickname: nickname)
} label: {
    HStack(spacing: 8) {
        Image(systemName: "square.and.arrow.up")
        Text("결과 공유하기")
    }
    .font(.system(size: 17, weight: .semibold, design: .rounded))
    .foregroundColor(.appText)
    .frame(maxWidth: .infinity)
    .frame(height: 52)
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.appCard)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appPrimaryStart.opacity(0.3), lineWidth: 1)
            )
    )
}
```

`appState.profile` 접근이 어려우면 `viewModel.nickname`을 별도 저장하거나 `ProfileRepository`에서 직접 로드.

## 주의사항

- `ImageRenderer`는 반드시 `@MainActor`에서 실행
- `UIActivityViewController` present는 반드시 메인 스레드
- iOS 시뮬레이터에서는 공유 시트가 다르게 보일 수 있음 (실기기 테스트 권장)
