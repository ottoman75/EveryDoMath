import Foundation
import SwiftUI

// App Store 스크린샷 촬영용 표본 데이터 주입.
//
// 부모 대시보드와 리더보드는 기록이 없으면 화면 대부분이 0 으로 비어 스토어
// 스크린샷으로 쓸 수 없다. 그렇다고 UI 테스트에서 20문제를 실제로 풀게 하면
// TimerRingView 가 0.1초마다 갱신되어 XCUITest 가 앱을 idle 로 보지 못하고
// 질의마다 정체가 쌓여 타임아웃이 난다(실측: 794초 후 실패).
//
// 그래서 데이터를 직접 넣는다.
//
// #if DEBUG && targetEnvironment(simulator) 로 이중 차단한다. DEBUG 만으로는
// 실기기 디버그 빌드에서도 실행되므로 시뮬레이터 조건을 함께 건다.
// 출시 빌드(Release)에는 이 코드 자체가 컴파일되지 않는다.
enum UITestSeed {

    static let launchArgument = "-UITestSeedData"

    /// 결과 화면을 바로 띄워 달라는 요청. 결과 화면은 20문제를 다 풀어야 도달하는데,
    /// 실제로 풀게 하면 위에 적은 타임아웃 문제가 그대로 재현된다. 그래서 시드로 만든
    /// 세션 하나를 네비게이션에 직접 밀어 넣는다.
    static let showResultArgument = "-UITestShowResult"

    /// 결과 화면 촬영용 세션. seed() 가 만들고 pushResultIfRequested() 가 꺼내 쓴다.
    private static var showcaseSession: GameSession?

    static func seedIfRequested() {
        #if DEBUG && targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }
        seed()
        #endif
    }

    /// 요청이 있으면 결과 화면을 네비게이션 스택에 올린다.
    @MainActor
    static func pushResultIfRequested(_ appState: AppState) {
        #if DEBUG && targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains(showResultArgument),
              let session = showcaseSession else { return }
        appState.navigationPath.append(AppDestination.result(session))
        #endif
    }

    #if DEBUG && targetEnvironment(simulator)
    private static func seed() {
        let profileRepo = ProfileRepository()
        let gameRepo = GameRepository()

        // 프로필 — 이미 있으면 통계만 덮어쓴다
        var profile = profileRepo.loadProfile() ?? PlayerProfile(nickname: "수학왕", preferredGrade: .grade4)
        profile.totalGamesPlayed = 47
        profile.bestScore = 920
        profile.totalXP = 1840
        profile.preferredGrade = .grade4
        profileRepo.saveProfile(profile)

        // 최근 7일 기록 — 오늘 포함 연속 플레이로 스트릭이 잡히게 한다
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        // 앞쪽을 0 으로 비워 스트릭을 3일로 만든다. 7일 연속이면 홈의 스트릭
        // 배지가 커져 하단 버튼이 화면 밖으로 밀린다(스크린샷에서 확인).
        let counts = [0, 0, 0, 0, 4, 5, 2]   // 6일 전 → 오늘
        var records: [DailyRecord] = []
        for (i, count) in counts.enumerated() {
            // calculateStreak 는 sessionsPlayed 가 아니라 DailyRecord 의 존재
            // 여부로 연속일을 센다. 안 한 날은 레코드를 만들지 않아야 한다.
            guard count > 0 else { continue }
            let daysAgo = 6 - i
            guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            var r = DailyRecord(dateString: fmt.string(from: date))
            r.sessionsPlayed = count
            r.bestScore = [640, 720, 830, 580, 760, 920, 810][i]
            records.append(r)
        }
        profileRepo.saveDailyRecords(records)

        // 연산별 정답률용 세션.
        //
        // 난수를 쓰지 않는다. 난수로 채우면 촬영할 때마다 정답률이 달라져,
        // 스토어에 올린 이미지를 나중에 다시 만들 수 없다. 실제로 연속 촬영에서
        // 곱셈이 56% → 65% → 66% 로 흔들렸다.
        //
        // 목표 상태는 하나다: **주황 구간(50~79%)에 곱셈 한 줄만** 들어가는 것.
        // 그 한 줄이 캡션 "약한 연산이 보여요"의 유일한 증거다. 두 줄이 주황이면
        // 어느 쪽이 약한 연산인지 그림이 말해주지 못한다.
        var sessions: [GameSession] = []
        var attemptCount: [MathOperation: Int] = [:]
        for _ in 0..<6 {
            // 4학년이어야 사칙연산 4종이 모두 출제된다. 3학년은 나눗셈이 없어
            // 부모 대시보드의 연산별 정답률에 ÷ 행이 생기지 않는다.
            let s = GameSession.createNew(grade: .grade4)
            for i in s.problems.indices {
                let p = s.problems[i]
                let n = attemptCount[p.operation, default: 0]
                attemptCount[p.operation] = n + 1
                // n 번째 시도를 맞히는지 여부를 주기로 결정한다. 예컨대 곱셈은
                // 3번에 2번 맞혀 정확히 66% 가 된다.
                let isCorrect: Bool
                switch p.operation {
                case .addition:       isCorrect = true                 // 100%
                case .subtraction:    isCorrect = n % 10 != 0          //  90%
                case .multiplication: isCorrect = n % 3 != 0           //  66% ← 유일한 주황
                case .division:       isCorrect = n % 8 != 0           //  87%
                }
                s.userAnswers[i] = isCorrect ? p.answerDisplayString : "0"
                s.perProblemTimes[i] = 5.0
            }
            s.timeTaken = s.perProblemTimes.reduce(0, +)
            s.maxCombo = longestCorrectRun(in: s)
            s.score = ScoreCalculator.calculate(session: s, maxCombo: s.maxCombo)
            s.gameGrade = GameGrade.from(score: s.score)
            sessions.append(s)
        }
        sessions.forEach { gameRepo.saveSession($0) }

        // 결과 화면용 세션은 저장소에 넣지 않는다.
        //
        // ResultViewModel.processResult() 가 화면에 뜰 때 직접 저장하므로 불필요하고,
        // 여기서 미리 넣으면 부모 대시보드의 연산별 정답률 집계에 섞인다. 이 세션의
        // 오답 2개는 섞인 문제 순서에 따라 매번 다른 연산에 떨어져서, 위에서 결정적으로
        // 만든 정답률이 다시 흔들렸다 (실측: ×66 → 69 → 70).
        showcaseSession = makeShowcaseSession()
    }

    /// 결과 화면 스크린샷용 세션. 위의 6개와 달리 난수를 쓰지 않는다 —
    /// 촬영할 때마다 점수와 등급이 달라지면 스토어에 올린 이미지와 다음 이미지가
    /// 다른 값을 말하게 된다.
    ///
    /// 20문제 중 18개 정답(4·8번만 오답), 문제당 4.2초 고정.
    /// 오답 위치를 고정했으므로 최대 콤보는 문제 구성과 무관하게 12로 결정된다.
    private static func makeShowcaseSession() -> GameSession {
        let s = GameSession.createNew(grade: .grade4)
        let wrongIndices: Set<Int> = [3, 7]
        for i in s.problems.indices {
            let p = s.problems[i]
            s.userAnswers[i] = wrongIndices.contains(i) ? "0" : p.answerDisplayString
            s.perProblemTimes[i] = 4.2
        }
        s.timeTaken = s.perProblemTimes.reduce(0, +)
        // 값을 지어내지 않고 정답 배열에서 센다. 임의의 숫자를 넣으면 결과 화면의
        // 콤보 표시와 점수의 콤보 보너스가 어긋난다.
        s.maxCombo = longestCorrectRun(in: s)
        s.score = ScoreCalculator.calculate(session: s, maxCombo: s.maxCombo)
        s.gameGrade = GameGrade.from(score: s.score)
        return s
    }

    private static func longestCorrectRun(in s: GameSession) -> Int {
        var best = 0
        var run = 0
        for i in s.problems.indices {
            if s.userAnswers[i] == s.problems[i].answerDisplayString {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        return best
    }
    #endif
}
