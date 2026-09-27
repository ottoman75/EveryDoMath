---
name: feature-orchestrator
description: "EveryDoMath 앱의 신규 기능 6가지(푸시알림, 오늘의도전, 결과공유, 부모대시보드, 가족리더보드, 학습목표)를 에이전트 팀으로 병렬 구현하는 오케스트레이터. '6가지 기능 구현', 'feature-orchestrator 실행' 요청 시 반드시 이 스킬을 사용할 것."
---

# Feature Orchestrator — 신규 기능 6종 구현

## 목표

EveryDoMath 앱에 6가지 사용자 참여/재방문 기능을 에이전트 팀으로 병렬 구현한다.

## 실행 모드: 팬아웃/팬인

- **Phase 1 (팬아웃):** 4개 구현 에이전트 병렬 실행
- **Phase 2 (팬인 + 통합):** feature-retention이 HomeView 통합
- **Phase 3 (순차):** feature-qa 빌드 검증

## 에이전트 구성

| 팀원 | 에이전트 | 담당 기능 | 핵심 파일 |
|------|---------|---------|---------|
| feature-retention | 커스텀 | 기능1(알림)+기능2(챌린지)+HomeView통합 | NotificationManager, DailyChallenge*, HomeView |
| feature-share | 커스텀 | 기능3(결과공유) | ShareCardView, ResultView |
| feature-parent | 커스텀 | 기능4(대시보드)+기능5(가족리더보드) | ParentDashboard*, FamilyGroup* |
| feature-goal | 커스텀 | 기능6(학습목표) | LearningGoal*, GoalSettings, GoalProgress |
| feature-qa | 커스텀 | 빌드검증 | xcodebuild |

## Phase 1: 준비

1. `_workspace/` 디렉토리 확인:
   ```bash
   ls /Users/otto/DevWork/EveryDoMath/_workspace/
   ```

2. 기존 코드 스냅샷 저장:
   - `AppState.swift` 현재 내용 → `_workspace/original_appstate.swift`
   - `HomeView.swift` 현재 내용 → `_workspace/original_homeview.swift`
   - `HomeViewModel.swift` 현재 내용 → `_workspace/original_homeviewmodel.swift`

## Phase 2: 에이전트 팀 구성 (팬아웃)

```
TeamCreate(
  team_name: "feature-team",
  members: [
    {
      name: "feature-retention",
      agent_type: "feature-retention",
      model: "opus",
      prompt: "feature-retention 에이전트입니다. feature-retention 스킬을 읽고 기능1(푸시 알림)과 기능2(오늘의 도전)를 구현하세요. 프로젝트 경로: /Users/otto/DevWork/EveryDoMath. 작업 순서: (1) 4개 신규 파일 생성, (2) parent-agent와 goal-agent로부터 HomeView 스니펫 SendMessage 수신 대기, (3) 스니펫 수신 후 HomeView.swift + HomeViewModel.swift 종합 업데이트. HomeView 수정 전에 반드시 parent와 goal의 완료 신호를 기다릴 것."
    },
    {
      name: "feature-share",
      agent_type: "feature-share",
      model: "opus",
      prompt: "feature-share 에이전트입니다. feature-share 스킬을 읽고 기능3(결과 카드 공유)을 구현하세요. 프로젝트 경로: /Users/otto/DevWork/EveryDoMath. 작업: ShareCardView.swift, View+ShareSheet.swift 신규 생성, ResultView.swift + ResultViewModel.swift 수정. 완료 후 TaskUpdate로 완료 표시."
    },
    {
      name: "feature-parent",
      agent_type: "feature-parent",
      model: "opus",
      prompt: "feature-parent 에이전트입니다. feature-parent 스킬을 읽고 기능4(부모 대시보드)와 기능5(가족 리더보드)를 구현하세요. 프로젝트 경로: /Users/otto/DevWork/EveryDoMath. 작업: FamilyGroup.swift, FamilyGroupRepository.swift, ParentDashboardView.swift, ParentDashboardViewModel.swift, FamilyLeaderboardView.swift 신규 생성. AppState.swift에 parentDashboard case 추가. 완료 후 feature-retention에게 SendMessage로 HomeView 버튼 스니펫 전달 (형식: {type: homeview_snippet, content: <코드>}). MathOperation에 symbol 프로퍼티와 CaseIterable이 없으면 추가."
    },
    {
      name: "feature-goal",
      agent_type: "feature-goal",
      model: "opus",
      prompt: "feature-goal 에이전트입니다. feature-goal 스킬을 읽고 기능6(학습 목표 설정)을 구현하세요. 프로젝트 경로: /Users/otto/DevWork/EveryDoMath. 작업: LearningGoal.swift, LearningGoalRepository.swift, GoalSettingsView.swift, GoalProgressView.swift 신규 생성. 완료 후 feature-retention에게 SendMessage로 HomeViewModel 추가 코드와 HomeView goalProgressSection 스니펫 전달 (형식: {type: homeview_snippet, content: <코드>}). NotificationManager는 feature-retention이 구현하므로 import만 사용."
    }
  ]
)
```

## Phase 3: 작업 등록

```
TaskCreate(tasks: [
  {
    title: "기능1+2: 알림+챌린지 구현",
    description: "NotificationManager, DailyChallenge 모델+저장소+뷰 생성",
    assignee: "feature-retention"
  },
  {
    title: "기능3: 결과 공유 구현",
    description: "ShareCardView, ResultView 수정",
    assignee: "feature-share"
  },
  {
    title: "기능4+5: 부모 대시보드+가족 리더보드 구현",
    description: "ParentDashboard, FamilyGroup 파일 생성, AppState 수정",
    assignee: "feature-parent"
  },
  {
    title: "기능6: 학습 목표 구현",
    description: "LearningGoal 모델+저장소+뷰 생성",
    assignee: "feature-goal"
  },
  {
    title: "HomeView 통합 (parent+goal 스니펫 적용)",
    description: "parent-agent, goal-agent 완료 후 HomeView 종합 업데이트",
    assignee: "feature-retention",
    depends_on: ["기능4+5: 부모 대시보드+가족 리더보드 구현", "기능6: 학습 목표 구현"]
  },
  {
    title: "빌드 검증",
    description: "xcodebuild BUILD SUCCEEDED 확인",
    assignee: "feature-qa",
    depends_on: ["HomeView 통합 (parent+goal 스니펫 적용)", "기능3: 결과 공유 구현"]
  }
])
```

## Phase 4: QA 검증 (팀 작업 완료 후)

모든 구현 에이전트 완료 확인 후 `feature-qa` 에이전트 실행:
- feature-qa 스킬 읽기
- 파일 존재 확인, 경계면 교차 검증, xcodebuild 실행
- BUILD SUCCEEDED 확인
- `_workspace/qa_report.md` 저장

## 파일 충돌 방지 규칙

| 파일 | 소유 에이전트 | 비고 |
|------|------------|------|
| `HomeView.swift` | feature-retention | 다른 에이전트 직접 수정 금지 |
| `HomeViewModel.swift` | feature-retention | 스니펫 수신 후 통합 |
| `EveryDoMathApp.swift` | feature-retention | 알림 권한 요청만 추가 |
| `AppState.swift` | feature-parent | parentDashboard case 추가 |
| `ResultView.swift` | feature-share | 공유 버튼만 추가 |
| `ResultViewModel.swift` | feature-share | shareResult() 추가 |
| `MathOperation.swift` | feature-parent | symbol, CaseIterable 추가 필요 시 |

## 에러 핸들링

- **에이전트 구현 실패:** 해당 기능 없이 나머지 진행, qa_report에 누락 명시
- **빌드 에러:** feature-qa가 직접 수정, 1회 재시도 후 재빌드
- **파일 충돌:** feature-retention이 최종 통합 책임자이므로, 중복 수정 감지 시 마지막 버전 기준으로 재통합

## 테스트 시나리오

### 정상 흐름
1. 4개 에이전트 병렬 실행 → 각자 신규 파일 생성
2. parent + goal → retention에 HomeView 스니펫 전달
3. retention이 HomeView 통합 완료
4. qa가 빌드 검증 → BUILD SUCCEEDED

### 에러 흐름
1. feature-parent Firestore 오류 → 로컬 데이터만으로 대시보드 구현 완료
2. feature-goal NotificationManager 참조 에러 → import 추가, qa가 수정
3. HomeView 통합 불완전 → qa 단계에서 grep으로 감지, 직접 추가

## 완료 기준

- [ ] 15개 이상 신규 파일 생성 완료
- [ ] HomeView에 3개 신규 섹션 (챌린지, 목표, 부모버튼) 포함
- [ ] AppState에 parentDashboard destination 추가
- [ ] xcodebuild BUILD SUCCEEDED
- [ ] `_workspace/qa_report.md` 생성
