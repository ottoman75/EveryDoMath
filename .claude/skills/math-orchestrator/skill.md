---
name: math-orchestrator
description: "EveryDoMath iOS 앱 전체 빌드를 오케스트레이션하는 마스터 스킬. 초등학생 수학 앱 구현, 에이전트 팀 조율, 도메인+UI 병렬 구현을 담당. '/math-orchestrator' 또는 'EveryDoMath 앱 빌드' 요청 시 반드시 이 스킬을 사용할 것."
---

# EveryDoMath 앱 빌드 오케스트레이터

## 목표
SwiftUI 기반 초등학생 수학 학습 앱을 에이전트 팀으로 구현한다.

## 실행 모드
**파이프라인 + 팬아웃 복합 패턴**
- Phase 1 (파이프라인): math-architect → 설계
- Phase 2 (팬아웃): math-domain + math-ui 병렬 구현
- Phase 3 (파이프라인): math-qa → 검증

## Phase 1: 아키텍처 설계 (순차)

`math-architect` 에이전트 실행 (서브 에이전트):
```
작업: EveryDoMath 앱 아키텍처 설계
- 기존 파일 읽기: EveryDoMath/ContentView.swift, EveryDoMathApp.swift
- 완전한 파일 구조 설계 (모든 파일 목록)
- 데이터 모델 스키마 명세
- math-domain / math-ui 담당 파일 분리
- _workspace/01_architect_plan.md 출력
```

## Phase 2: 병렬 구현 (에이전트 팀)

`math-domain` + `math-ui` 에이전트 팀 구성:

**math-domain 작업:**
1. `_workspace/01_architect_plan.md` 읽기
2. `math-problem-generator` 스킬 참조
3. 모든 도메인/데이터/ViewModel 파일 구현
4. 완료 후 `math-ui`에게 SendMessage: ViewModel API 명세 전달

**math-ui 작업:**
1. `_workspace/01_architect_plan.md` 읽기
2. `math-ui-design` 스킬 참조
3. math-domain으로부터 ViewModel API 받은 후 모든 View 구현
4. 필요시 math-domain에게 추가 API 요청

**팀 통신 프로토콜:**
- math-domain → math-ui: `{viewModels: [...], types: [...], publishers: [...]}`
- math-ui → math-domain: 추가 필요 메서드/프로퍼티 요청

## Phase 3: QA 검증 (순차)

`math-qa` 에이전트 실행:
```
작업: 구현된 모든 Swift 파일 검증
- 모든 Swift 파일 읽기
- 타입 정합성, 바인딩 일관성 확인
- _workspace/03_qa_report.md 출력
- 이슈 발견 시 즉시 수정
```

## 데이터 전달 프로토콜

```
_workspace/
├── 01_architect_plan.md    (Phase1 → Phase2 입력)
└── 03_qa_report.md         (Phase3 출력)
```

## 에러 핸들링
- Phase 1 실패 시: 오케스트레이터가 직접 기본 계획 수립 후 Phase 2 진행
- Phase 2 충돌 시: math-domain/math-ui 간 API 협의 1회 허용
- Phase 3 이슈 시: 해당 에이전트에 수정 요청 1회, 재실패 시 보고서에 명시

## 앱 기능 요구사항 (구현 시 준수)

### 핵심 기능
1. **학년 선택** (1-6학년) - 홈 화면
2. **프로필 설정** - 닉네임 입력, 학년 기본값
3. **게임 세션** - 20문제, 학년별 수학 문제
4. **타이머** - 문제당 30초, 시각적 긴박감
5. **즉각 피드백** - 정답/오답 0.8초 표시 후 자동 다음 문제
6. **점수 계산** - 정확도 + 속도 기반
7. **결과 화면** - 점수, 등급(S/A/B/C/D), 상세 통계
8. **로컬 리더보드** - UserDefaults 기반, 상위 20명
9. **일일 스트릭** - 연속 플레이 일수 추적
10. **업적 시스템** - 조건별 배지 지급

### 업적 조건
- 첫 게임 완료 (신인)
- 7일 연속 플레이 (1주일 챔피언)  
- 30일 연속 플레이 (한달 마스터)
- 100점 만점 달성 (완벽주의자)
- 전체 정답 (퍼펙트)
- 30초 이내 전 문제 완료 (스피드 킹)
- 학년 최고점 달성 (학년 1위)

### 등급 기준
- S: 90점 이상 + 정답률 90% 이상
- A: 80점 이상
- B: 70점 이상
- C: 60점 이상
- D: 60점 미만

## 테스트 시나리오

### 정상 흐름
1. 앱 최초 실행 → 프로필 설정 → 학년 선택 → 게임 시작
2. 20문제 진행 → 각 정답/오답 피드백 → 결과 화면
3. 업적 달성 → 리더보드 등록 → 홈으로

### 에러 흐름
1. 타이머 만료 → 오답 처리 → 자동 다음 문제
2. 앱 종료 후 재시작 → 스트릭 유지 확인
3. 리더보드 20명 초과 → 하위 점수 제거

## 구현 우선순위
1. 필수: Domain 모델 + ProblemGenerator + GameViewModel
2. 필수: GameView + TimerRingView + NumpadView
3. 필수: 결과 화면 + 점수 계산
4. 중요: 리더보드 + 스트릭
5. 선택: 업적 애니메이션 상세화
