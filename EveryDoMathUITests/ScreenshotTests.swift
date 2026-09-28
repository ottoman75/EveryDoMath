import XCTest

/// App Store 스크린샷 캡처용.
///
/// 앱에 접근성 식별자가 없어 화면에 보이는 한국어 문구로 탐색한다.
/// 문구가 바뀌면 여기도 같이 고쳐야 한다.
///
/// 캡처된 이미지는 XCTAttachment 로 붙어 .xcresult 안에 들어가고,
/// Scripts/extract_screenshots.sh 가 꺼내서 fastlane/screenshots 로 옮긴다.
/// 실행: xcodebuild test -only-testing:EveryDoMathUITests/ScreenshotTests
/// 일반 테스트에서는 -skip-testing:EveryDoMathUITests 로 제외한다.
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
                                "-UITestSeedData"]   // 통계·기록 표본 주입
        app.launch()
    }

    /// iOS 시스템 권한 팝업이 떠 있으면 닫는다.
    ///
    /// XCUITest 에서 시스템 알림은 앱이 아니라 springboard 소속이다.
    /// 버튼을 라벨로 찾지 않는다 — 팝업은 앱이 아니라 *시뮬레이터 시스템* 언어를 따르므로
    /// 한국어 스크린샷을 찍는 중에도 일본어로 뜰 수 있다 (실제로 그렇게 찍혔다).
    /// 알림 권한 팝업의 첫 버튼은 거부("허용 안 함")이고, 그쪽이 우리가 원하는 선택이다.
    private func dismissSystemAlertIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 5) else { return }
        let deny = alert.buttons.element(boundBy: 0)
        guard deny.exists else { return }
        deny.tap()
        sleep(1)
    }

    /// 키보드를 내린다. 키보드가 올라와 있으면 화면 하단이 통째로 가려진다.
    private func dismissKeyboard() {
        if app.keyboards.element.exists {
            app.buttons["Return"].firstMatch.tap()
        }
        if app.keyboards.element.exists {
            // Return 이 없는 키패드는 바깥을 눌러 내린다
            app.staticTexts.firstMatch.tap()
        }
        sleep(1)
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// 요소가 나타날 때까지 기다린다. 없으면 false.
    @discardableResult
    private func waitFor(_ element: XCUIElement, _ seconds: TimeInterval = 10) -> Bool {
        element.waitForExistence(timeout: seconds)
    }



    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        // ── 1. 최초 실행: 프로필 설정 ───────────────────────────
        let nicknameField = app.textFields.firstMatch
        if waitFor(nicknameField, 8) {
            // 알림 권한 팝업이 화면을 가린다. 게다가 "앱이 권한을 요구하는 장면"은
            // "묻지 않고 바로 시작" 메시지와 정면으로 모순된다. 먼저 닫는다.
            dismissSystemAlertIfPresent()

            // 채우고 나서 찍는다. 빈 입력칸과 회색 시작하기 버튼은 "별명만 정하면
            // 된다"가 아니라 "앱이 뭔가 요구한다"로 읽힌다.
            nicknameField.tap()
            nicknameField.typeText("수학왕")

            // 4학년 — 시드의 preferredGrade 와 맞춘다. 여기만 3학년이면
            // 프로필 설정 스크린샷과 홈 스크린샷이 서로 다른 학년을 보여준다.
            let grade4 = app.buttons.containing(.staticText, identifier: "4").firstMatch
            if grade4.exists { grade4.tap() }

            // 키보드가 화면 절반을 가린 채로 찍히면 안 된다
            dismissKeyboard()
            snap("01_프로필설정")

            let startSetup = app.buttons["시작하기 →"]
            if waitFor(startSetup, 5) { startSetup.tap() }

            // 프로필 설정이 통계 0 인 새 프로필을 만들어 시드를 덮어쓴다.
            // 재시작하면 시드가 기존 프로필의 통계만 갱신한다.
            _ = app.buttons["시작하기"].waitForExistence(timeout: 20)
            app.terminate()
            app.launch()
        }

        // ── 2. 홈 ──────────────────────────────────────────────
        let startButton = app.buttons["시작하기"]
        XCTAssertTrue(waitFor(startButton, 15), "홈 화면 진입 실패")
        sleep(1)
        // 스크롤하면 콘텐츠가 상태바와 겹친다. 한 화면에 들어가야 한다.
        XCTAssertTrue(app.buttons["가족 리더보드"].isHittable,
                      "하단 버튼이 잘렸다 — 홈 레이아웃이 한 화면을 넘는다")
        snap("02_홈")

        // ── 3. 게임 ────────────────────────────────────────────
        startButton.tap()
        // 숫자 키패드가 뜰 때까지 대기
        let key7 = app.buttons["7"]
        XCTAssertTrue(waitFor(key7, 15), "게임 화면 진입 실패")
        sleep(1)

        // 첫 문제가 한 자리 수끼리면 다시 뽑는다.
        //
        // 이 화면이 스토어 5장 중 첫 장이다. 그런데 문제는 매판 난수라
        // 4학년인데 `9 ÷ 3` 이 나온 적이 있다 — 앱을 대표하지 못한다.
        // 버리는 것은 뽑기 결과뿐이고, 남는 것도 앱이 그 학년에 실제로 내는 문제다.
        for _ in 0..<8 {
            if problemLooksRepresentative() { break }
            rerollProblem()
        }
        snap("03_게임")

        // 몇 문제 풀어 콤보/피드백이 있는 화면을 만든다
        for _ in 0..<3 {
            if app.buttons["7"].exists { app.buttons["7"].tap() }
            if app.buttons["확인"].exists {
                app.buttons["확인"].tap()
            } else if app.buttons.matching(NSPredicate(format: "label CONTAINS '='")).firstMatch.exists {
                app.buttons.matching(NSPredicate(format: "label CONTAINS '='")).firstMatch.tap()
            }
            sleep(2)
        }
        snap("04_게임_진행중")

        // ── 4. 게임을 빠져나와 나머지 화면 캡처 ────────────────
        // 20문제를 실제로 풀지 않는다. TimerRingView 가 0.1초마다 갱신되어
        // XCUITest 가 앱을 idle 로 보지 못하고 질의마다 정체가 쌓여
        // 타임아웃이 난다(실측 794초 후 실패). 통계는 -UITestSeedData 로 넣는다.
        let quit = app.buttons["포기"]
        if waitFor(quit, 5) {
            quit.tap()
            let confirm = app.alerts.buttons["포기"]
            if waitFor(confirm, 5) { confirm.tap() }
        }

        // ── 5. 리더보드 ────────────────────────────────────────
        let leaderboard = app.buttons["리더보드"]
        if waitFor(leaderboard, 10) {
            leaderboard.tap()
            sleep(3)
            snap("05_리더보드")
            // 뒤로
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }

        // ── 6. 부모 대시보드 (부모 게이트 통과 필요) ────────────
        let parent = app.buttons["부모 대시보드"]
        if waitFor(parent, 10) {
            parent.tap()
            XCTAssertTrue(passParentGate(), "부모 게이트를 통과하지 못했다")
            sleep(3)
            // 게이트 화면이 아니라 대시보드가 찍혔는지 확인한다.
            // 확인하지 않으면 게이트 화면이 스토어 스크린샷으로 올라간다.
            XCTAssertFalse(app.staticTexts["보호자 확인"].exists,
                           "게이트 화면이 남아 있다 — 대시보드에 도달하지 못했다")
            snap("06_부모대시보드")
        }

        // ── 7. 결과 ────────────────────────────────────────────
        // 20문제를 실제로 풀지 않는다(위 4번 참조). 시드가 만들어 둔 결과 세션을
        // 네비게이션에 직접 올리도록 인자를 바꿔 재실행한다.
        // 그 세션은 난수를 쓰지 않으므로 점수·등급이 촬영할 때마다 같다.
        app.terminate()
        app.launchArguments += ["-UITestShowResult"]
        app.launch()

        let playAgain = app.buttons["다시 하기"]
        XCTAssertTrue(waitFor(playAgain, 15), "결과 화면 진입 실패")
        // 점수 카운트업 애니메이션이 끝나야 최종 점수가 찍힌다
        sleep(3)
        snap("07_결과")
    }


    /// 화면에 떠 있는 문제가 스토어에 쓸 만한가.
    /// 판단 기준은 하나 — 피연산자 중 적어도 하나가 두 자리 이상인가.
    private func problemLooksRepresentative() -> Bool {
        guard let label = problemLabel() else { return true }   // 못 읽으면 통과시킨다
        return label.contains { $0.isNumber } &&
            label.split(whereSeparator: { !$0.isNumber })
                 .contains { $0.count >= 2 }
    }

    /// `9 ÷ 3 = ?` 형태의 문제 문구를 찾는다.
    private func problemLabel() -> String? {
        app.staticTexts.allElementsBoundByIndex
            .map(\.label)
            .first { $0.hasSuffix("= ?") }
    }

    /// 포기하고 다시 시작해 새 문제를 뽑는다.
    private func rerollProblem() {
        let quit = app.buttons["포기"]
        guard waitFor(quit, 5) else { return }
        quit.tap()
        let confirm = app.alerts.buttons["포기"]
        if waitFor(confirm, 5) { confirm.tap() }
        let start = app.buttons["시작하기"]
        guard waitFor(start, 10) else { return }
        start.tap()
        _ = waitFor(app.buttons["7"], 15)
        sleep(1)
    }

    /// 부모 게이트의 "십사 곱하기 십칠" 형식을 읽어 정답을 넣는다.
    /// 화면 문구가 바뀌면 여기도 같이 고쳐야 한다.
    @discardableResult
    private func passParentGate() -> Bool {
        guard app.staticTexts["보호자 확인"].waitForExistence(timeout: 10) else {
            return true   // 게이트가 없는 빌드
        }
        let words = ["십": 10, "십일": 11, "십이": 12, "십삼": 13, "십사": 14,
                     "십오": 15, "십육": 16, "십칠": 17, "십팔": 18, "십구": 19]
        for text in app.staticTexts.allElementsBoundByIndex where text.exists {
            let parts = text.label.components(separatedBy: " 곱하기 ")
            guard parts.count == 2,
                  let a = words[parts[0].trimmingCharacters(in: .whitespaces)],
                  let b = words[parts[1].trimmingCharacters(in: .whitespaces)] else { continue }
            let field = app.textFields.firstMatch
            guard field.waitForExistence(timeout: 5) else { return false }
            field.tap()
            field.typeText(String(a * b))
            app.buttons["확인"].tap()
            return !app.staticTexts["보호자 확인"].waitForExistence(timeout: 3)
        }
        return false
    }
}
