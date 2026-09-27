---
name: feature-qa
description: "EveryDoMath 신규 기능(푸시알림, 오늘의도전, 공유, 부모대시보드, 가족리더보드, 학습목표) 구현 후 xcodebuild 빌드 검증 및 통합 정합성 확인. feature-qa 에이전트 실행 시 반드시 이 스킬을 사용."
---

# Feature QA — 빌드 검증

## 검증 순서

### Step 1: 파일 존재 확인

```bash
find /Users/otto/DevWork/EveryDoMath/EveryDoMath -name "*.swift" | sort | grep -E "Notification|DailyChallenge|ShareCard|ShareSheet|FamilyGroup|ParentDashboard|FamilyLeaderboard|LearningGoal|GoalSettings|GoalProgress"
```

누락된 파일은 즉시 생성.

### Step 2: 시뮬레이터 ID 확인

```bash
xcrun simctl list devices available | grep "Booted\|iPhone 17" | head -5
```

### Step 3: 빌드 실행

```bash
cd /Users/otto/DevWork/EveryDoMath && \
xcodebuild -project EveryDoMath.xcodeproj \
  -scheme EveryDoMath \
  -destination 'platform=iOS Simulator,id=1DD3D6AA-328F-4A8F-9484-11B8E5241DF2' \
  build 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
```

### Step 4: 에러 분류 및 수정

| 에러 유형 | 해결 방법 |
|----------|----------|
| `No such module` | import 문 확인, 프로젝트에 패키지 추가 여부 확인 |
| `cannot find type` | 파일에 타입 정의 확인, import 누락 확인 |
| `cannot convert value of type` | 타입 캐스팅 수정, 옵셔널 처리 추가 |
| `value of type has no member` | 프로퍼티/메서드 존재 확인, 스펠링 확인 |
| `missing return` | return 문 추가 또는 함수 구조 수정 |
| `@MainActor` 관련 | async 컨텍스트 확인, Task { } 래핑 |

### Step 5: 경계면 교차 검증

에러 수정 후 아래 항목 수동 확인:

```bash
# HomeView에 새 섹션들이 있는지 확인
grep -n "DailyChallengeCardView\|GoalProgressView\|parentDashboard" \
  /Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/Home/HomeView.swift

# AppState에 parentDashboard destination이 있는지
grep -n "parentDashboard" \
  /Users/otto/DevWork/EveryDoMath/EveryDoMath/App/AppState.swift

# ResultView에 공유 버튼이 있는지
grep -n "shareResult\|공유\|square.and.arrow" \
  /Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/Result/ResultView.swift

# ParentDashboardView에 GoalSettingsView 탭이 있는지
grep -n "GoalSettingsView" \
  /Users/otto/DevWork/EveryDoMath/EveryDoMath/Presentation/Parent/ParentDashboardView.swift

# NotificationManager가 EveryDoMathApp에서 호출되는지
grep -n "NotificationManager" \
  /Users/otto/DevWork/EveryDoMath/EveryDoMath/EveryDoMathApp.swift
```

누락된 항목은 해당 파일을 직접 수정.

### Step 6: 재빌드 확인

수정 후 반드시 재빌드하여 `BUILD SUCCEEDED` 확인:

```bash
cd /Users/otto/DevWork/EveryDoMath && \
xcodebuild -project EveryDoMath.xcodeproj \
  -scheme EveryDoMath \
  -destination 'platform=iOS Simulator,id=1DD3D6AA-328F-4A8F-9484-11B8E5241DF2' \
  build 2>&1 | tail -5
```

## 보고서 출력

`_workspace/qa_report.md`에 저장:
```markdown
# QA 보고서

## 빌드 결과: SUCCEEDED / FAILED

## 발견된 이슈 및 수정 내역
- [파일명:라인] 이슈 설명 → 수정 내용

## 경계면 검증 결과
- HomeView 통합: ✅ / ❌
- AppState destination: ✅ / ❌
- ResultView 공유 버튼: ✅ / ❌
- ParentDashboard GoalSettings 탭: ✅ / ❌
- EveryDoMathApp 알림 권한: ✅ / ❌

## 최종 상태
BUILD SUCCEEDED — 모든 기능 구현 완료
```
