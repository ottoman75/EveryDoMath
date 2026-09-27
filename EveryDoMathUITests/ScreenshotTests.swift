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
            snap("01_프로필설정")
            nicknameField.tap()
            nicknameField.typeText("수학왕")

            // 3학년 선택 (학년 칩은 숫자 텍스트로 노출된다)
            let grade3 = app.buttons.containing(.staticText, identifier: "3").firstMatch
            if grade3.exists { grade3.tap() }

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
