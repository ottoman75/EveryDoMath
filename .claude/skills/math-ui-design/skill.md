---
name: math-ui-design
description: "EveryDoMath 앱의 커스텀 SwiftUI UI 디자인 가이드. 컬러 팔레트, 컴포넌트 명세, 애니메이션 패턴 포함. 시스템 기본 UI가 아닌 고품질 커스텀 UI 구현 시 반드시 이 스킬을 사용할 것."
---

# EveryDoMath UI 디자인 시스템

## 컬러 시스템

```swift
// Color+Extensions.swift
extension Color {
    static let appPrimaryStart = Color(hex: "7C3AED")   // 보라
    static let appPrimaryEnd = Color(hex: "EC4899")     // 핑크
    static let appSuccess = Color(hex: "10B981")        // 초록
    static let appWarning = Color(hex: "F59E0B")        // 오렌지
    static let appDanger = Color(hex: "EF4444")         // 빨강
    static let appBackground = Color(hex: "0F172A")     // 딥 네이비
    static let appCard = Color(hex: "1E293B")           // 카드 배경
    static let appCardBorder = Color(hex: "334155")     // 카드 테두리
    static let appText = Color(hex: "F1F5F9")           // 기본 텍스트
    static let appSubtext = Color(hex: "94A3B8")        // 보조 텍스트
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
```

## 타이포그래피
- 문제 텍스트: `.system(size: 52, weight: .bold, design: .rounded)`
- 제목: `.system(size: 28, weight: .bold, design: .rounded)`
- 부제목: `.system(size: 18, weight: .semibold)`
- 본문: `.system(size: 16, weight: .regular)`
- 캡션: `.system(size: 13, weight: .medium)`

## 핵심 컴포넌트 명세

### TimerRingView
```swift
// 원형 타이머 링 - 시간에 따라 색상 변화
// 30초→15초: 초록
// 15초→5초: 오렌지  
// 5초→0초: 빨강 + 펄스 애니메이션
struct TimerRingView: View {
    let totalTime: Double  // 총 시간(초)
    let remaining: Double  // 남은 시간(초)
    // 원형 프로그레스 바, 중앙에 남은 초 표시
}
```

### NumpadView
```swift
// 커스텀 숫자 키패드
// 3×4 그리드: 1-9, ., 0, ⌫
// 각 버튼: 크고 둥근 카드 스타일 (60×60pt)
// 탭 시 haptic feedback
struct NumpadView: View {
    @Binding var inputText: String
    let onSubmit: () -> Void
}
```

### FeedbackOverlayView
```swift
// 정답/오답 시 오버레이
// 정답: 초록 배경 + "✓ 정답!" + 획득 점수
// 오답: 빨강 배경 + "✗ 오답!" + 정답 표시
// 0.8초 표시 후 자동 사라짐
struct FeedbackOverlayView: View {
    let isCorrect: Bool
    let earnedScore: Int
    let correctAnswer: String
}
```

### ProblemCardView
```swift
// 문제 카드 - 메인 화면 중앙
// 둥근 카드(cornerRadius: 24)
// 그라데이션 보더
// 문제 텍스트 크게 표시
// 애니메이션: 새 문제 등장 시 slide + scale
struct ProblemCardView: View {
    let problem: MathProblem
    let questionNumber: Int
    let totalQuestions: Int
}
```

### GradeBadge
```swift
// 학년 배지 - 홈 화면용
// 원형 또는 둥근 사각형
// 학년별 고유 색상 그라데이션
struct GradeBadgeView: View {
    let grade: Grade
    let isSelected: Bool
}
```

## 애니메이션 패턴

### 정답 피드백
```swift
// 초록 펄스 + 체크마크 scale
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
    showCorrectFeedback = true
}
```

### 오답 피드백 (흔들기)
```swift
// shake offset
withAnimation(.default.repeatCount(3, autoreverses: true)) {
    shakeOffset = 10
}
```

### 타이머 긴박감 (5초 이하)
```swift
// 빨간 펄스
withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
    timerPulse = true
}
```

### 점수 카운트업
```swift
// 숫자가 빠르게 올라가는 효과
Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { ... }
```

## 화면 레이아웃 원칙
1. **게임 화면**: 타이머(상단) - 문제번호 - 문제카드(중앙) - 입력창 - 숫자패드(하단)
2. **홈 화면**: 헤더(프로필/스트릭) - 학년선택 - 오늘의기록 - 시작버튼
3. **결과 화면**: 점수(크게) - 등급배지 - 정답률/소요시간 - 업적 - 리더보드 진입
4. **리더보드**: 내 순위 강조 - 순위 리스트 (카드형)

## Safe Area & 반응형
- `.ignoresSafeArea()` 배경에만 적용
- GeometryReader로 기기 크기 감지
- 작은 화면(SE): 글자 크기/패딩 축소
