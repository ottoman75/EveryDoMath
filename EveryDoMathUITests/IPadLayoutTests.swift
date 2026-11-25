import XCTest

/// iPad 레이아웃 점검용 캡처 (진단).
///
/// Guideline 4 로 두 번 반려된 뒤 iPad 를 정식 지원하면서 만들었다.
/// 시드 데이터로 홈부터 시작해 주요 화면을 돌며 스크린샷만 남긴다.
final class IPadLayoutTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
                                "-UITestSeedData"]
        app.launch()
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func back() {
        let b = app.navigationBars.buttons.firstMatch
        if b.exists { b.tap(); sleep(2) }
    }

    func testCaptureIPadScreens() throws {
        _ = app.buttons["시작하기"].waitForExistence(timeout: 25)
        sleep(2)
        snap("P1_홈")

        if app.buttons["리더보드"].exists {
            app.buttons["리더보드"].tap(); sleep(3)
            snap("P2_리더보드")
            back()
        }

        if app.buttons["가족 리더보드"].exists {
            app.buttons["가족 리더보드"].tap(); sleep(3)
            snap("P3_가족리더보드")
            back()
        }

        let profileIcon = app.buttons["person.circle.fill"]
        if profileIcon.exists {
            profileIcon.tap(); sleep(3)
            snap("P4_프로필")
            back()
        }

        if app.buttons["부모 대시보드"].exists {
            app.buttons["부모 대시보드"].tap(); sleep(2)
            snap("P5_부모게이트")
        }
    }
}
