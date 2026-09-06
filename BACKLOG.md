# EveryDoMath 백로그

> 세션 자동 점검(`session_check.py`)이 이 파일을 읽습니다.
> 형식: `- [ ] (P0|P1|P2) 항목` — 체크된 항목은 완료로 집계됩니다.
> 자동 진행을 원하지 않는 항목은 `(HOLD)` 를 붙이세요.

## 진행 중 / 대기

- [ ] (P0) (HOLD) Firebase 보안 규칙 점검 — 결정·확인 필요
      저장소가 **공개**라 plist는 .gitignore로 제외했지만, 앱 번들에는 그대로 들어가므로
      키는 어차피 추출 가능하다. Firebase iOS 키는 원래 비밀이 아니고 실제 방어선은
      Firestore 보안 규칙과 App Check이다. 리더보드·가족그룹이 Firestore를 쓰므로
      규칙이 인증된 사용자만 자기 문서를 쓰도록 돼 있는지 콘솔에서 확인할 것
- [ ] (P1) 소수 나눗셈 난이도 조정 결과 실기 검증 — 문제 표본이 실제로 6학년 범위인지
- [ ] (P2) 상단바 레이아웃의 `Color.clear.frame(width: 60)` 스페이서를 매직넘버 없이 재작성

## 완료

- [x] 미커밋 2건 커밋 (670b685) — 소수 나눗셈 난이도 완화 + 게임 화면 나가기 버튼 재배치. 빌드 통과
- [x] `.gitignore` 추가 — GoogleService-Info.plist(공개 저장소), `_workspace/`, `.claude/`, Xcode 사용자 설정 제외
