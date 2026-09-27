---
name: monetize-trial
description: EveryDoMath 무료 체험 스킬. 잠긴 학년에 5문제 trial을 구현한다. 무료 체험/trial 관련 요청 시 반드시 이 스킬을 사용할 것.
---

# 무료 체험 구현 스킬

프로젝트 경로: `/Users/otto/DevWork/EveryDoMath`

## 작업 1: TrialManager.swift 생성

경로: `/Users/otto/DevWork/EveryDoMath/EveryDoMath/Data/Repository/TrialManager.swift`

```swift
import Foundation

enum TrialManager {
    static let trialQuestionCount = 5

    static func isTrialAvailable(for grade: Grade) -> Bool {
        guard !grade.isFree else { return false }
        return !UserDefaults.standard.bool(forKey: trialKey(grade))
    }

    static func markTrialUsed(for grade: Grade) {
        UserDefaults.standard.set(true, forKey: trialKey(grade))
    }

    private static func trialKey(_ grade: Grade) -> String {
        "trial_used_grade_\(grade.rawValue)"
    }
}
```

## 작업 2: ProblemGenerator 확인

파일: `EveryDoMath/Domain/Logic/ProblemGenerator.swift`

`generate(grade:)` 함수 시그니처 확인 후:
- `count` 파라미터가 있으면 그대로 사용
- 없으면 `generate(grade:count:)` 오버로드 추가:
  ```swift
  static func generate(grade: Grade, count: Int) -> [MathProblem] {
      Array(generate(grade: grade).prefix(count))
  }
  ```

## 작업 3: HomeViewModel.swift 수정

파일: `/Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/Home/HomeViewModel.swift`

`createNewSession()` 아래에 trial 세션 생성 메서드 추가:
```swift
func createTrialSession() -> GameSession {
    let problems = ProblemGenerator.generate(grade: selectedGrade, count: TrialManager.trialQuestionCount)
    return GameSession(grade: selectedGrade, problems: problems)
}
```

## 작업 4: HomeView.swift의 startButton 수정

파일: `/Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/Home/HomeView.swift`

현재 startButton action:
```swift
if IAPManager.shared.isGradeUnlocked(viewModel.selectedGrade) {
    let session = viewModel.createNewSession()
    appState.navigationPath.append(AppDestination.game(session))
} else {
    showIAPStore = true
}
```

변경 후:
```swift
let grade = viewModel.selectedGrade
if IAPManager.shared.isGradeUnlocked(grade) {
    let session = viewModel.createNewSession()
    appState.navigationPath.append(AppDestination.game(session))
} else if TrialManager.isTrialAvailable(for: grade) {
    let session = viewModel.createTrialSession()
    TrialManager.markTrialUsed(for: grade)
    appState.navigationPath.append(AppDestination.game(session))
} else {
    showIAPStore = true
}
```

## 작업 5: trial 관련 strings 추가

**ko.lproj/Localizable.strings:**
```
/* Trial */
"trial.label" = "체험";
"trial.questions_count" = "(%d문제 무료 체험)";
```

**en.lproj/Localizable.strings:**
```
/* Trial */
"trial.label" = "Trial";
"trial.questions_count" = "(%d questions free trial)";
```

**ja.lproj/Localizable.strings:**
```
/* Trial */
"trial.label" = "体験";
"trial.questions_count" = "(%d問 無料体験)";
```

## 작업 6: GradeSelectorView trial 뱃지 (선택)

GradeSelectorView.swift에서 잠긴 학년에 trial 가능 여부 표시:
- trial 가능: lock 아이콘 대신 "FREE" 뱃지 (초록색)
- trial 소진 + 미구매: 기존 lock 아이콘

파일: `/Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/Components/GradeSelectorView.swift`

현재 lock 뱃지 코드 수정:
```swift
if !isUnlocked {
    let trialAvailable = TrialManager.isTrialAvailable(for: grade)
    if trialAvailable {
        Text("trial.label")
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.appSuccess))
            .padding(4)
    } else {
        Image(systemName: "lock.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(3)
            .background(Circle().fill(Color.appSubtext.opacity(0.8)))
            .padding(4)
    }
}
```

## 주의사항
- `IAPManager.swift`, `IAPStoreView.swift`, `.storekit` 수정 금지 (monetize-iap 에이전트 담당)
- `GameViewModel.swift`, `GameView.swift` 수정 불필요 — trial은 HomeView에서 세션 생성 시점에 처리
- L("trial.label") 형태로 LocalizedStringKey 사용 시 L() 함수 확인 필요 (있으면 사용, 없으면 String(localized:) 사용)
