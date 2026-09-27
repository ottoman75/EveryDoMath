---
name: monetize-qa
description: monetize-iap + monetize-trial 구현 후 빌드 검증 스킬.
---

# 수익화 QA 스킬

프로젝트 경로: `/Users/otto/DevWork/EveryDoMath`

## 빌드 검증

```bash
xcodebuild \
  -project /Users/otto/DevWork/EveryDoMath/EveryDoMath.xcodeproj \
  -scheme EveryDoMath \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  build 2>&1 | tail -50
```

## 파일 존재 확인
- `EveryDoMath/Data/Repository/TrialManager.swift` 존재
- `EveryDoMath/Data/Repository/IAPManager.swift`에 `subscriptionMonthly`, `subscriptionYearly` 존재
- `EveryDoMath.storekit`에 `subscriptionGroups` 비어있지 않음
- `GradeSelectorView.swift`에 `TrialManager.isTrialAvailable` 참조

## 에러 처리
- 에러 발생 시 해당 파일 읽고 직접 수정, 1회 재빌드
- 결과를 `_workspace/monetize_qa_report.md`에 저장
