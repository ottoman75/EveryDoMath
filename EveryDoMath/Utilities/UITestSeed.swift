import Foundation

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

    static func seedIfRequested() {
        #if DEBUG && targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }
        seed()
        #endif
    }

    #if DEBUG && targetEnvironment(simulator)
    private static func seed() {
        let profileRepo = ProfileRepository()
        let gameRepo = GameRepository()

        // 프로필 — 이미 있으면 통계만 덮어쓴다
        var profile = profileRepo.loadProfile() ?? PlayerProfile(nickname: "수학왕", preferredGrade: .grade3)
        profile.totalGamesPlayed = 47
        profile.bestScore = 920
        profile.totalXP = 1840
        profile.preferredGrade = .grade3
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

        // 연산별 정답률용 세션 — 연산마다 다른 정답률이 나오도록 섞는다
        var sessions: [GameSession] = []
        for _ in 0..<6 {
            let s = GameSession.createNew(grade: .grade3)
            for i in s.problems.indices {
                let p = s.problems[i]
                // 곱셈을 가장 낮게, 덧셈을 가장 높게 만들어 차이를 보여준다
                let hitRate: Double
                switch p.operation {
                case .addition:       hitRate = 0.95
                case .subtraction:    hitRate = 0.85
                case .multiplication: hitRate = 0.62
                case .division:       hitRate = 0.74
                }
                s.userAnswers[i] = Double.random(in: 0...1) < hitRate
                    ? p.answerDisplayString
                    : "0"
                s.perProblemTimes[i] = Double.random(in: 2.5...9.0)
            }
            s.timeTaken = s.perProblemTimes.reduce(0, +)
            s.maxCombo = Int.random(in: 4...12)
            s.score = ScoreCalculator.calculate(session: s, maxCombo: s.maxCombo)
            s.gameGrade = GameGrade.from(score: s.score)
            sessions.append(s)
        }
        sessions.forEach { gameRepo.saveSession($0) }
    }
    #endif
}
