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
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
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
        }

        // ── 2. 홈 ──────────────────────────────────────────────
        let startButton = app.buttons["시작하기"]
        XCTAssertTrue(waitFor(startButton, 15), "홈 화면 진입 실패")
        sleep(1)
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

        // ── 4. 게임을 끝내지 않고 홈으로 돌아가 나머지 화면 캡처 ──
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

        // ── 6. 부모 대시보드 ───────────────────────────────────
        let parent = app.buttons["부모 대시보드"]
        if waitFor(parent, 10) {
            parent.tap()
            sleep(3)
            snap("06_부모대시보드")
        }
    }
}
