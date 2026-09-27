import XCTest

/// 부모 게이트와 가족 리더보드 분리 결과를 눈으로 확인하기 위한 촬영.
/// 실행: xcodebuild test -only-testing:EveryDoMathUITests/GateScreenshotTests
final class GateScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
    }

    private func snap(_ name: String) {
        let s = XCTAttachment(screenshot: app.screenshot())
        s.name = name; s.lifetime = .keepAlways; add(s)
    }

    @MainActor
    func testGateAndFamilyScreen() throws {
        // 프로필 설정
        let field = app.textFields.firstMatch
        if field.waitForExistence(timeout: 10) {
            field.tap(); field.typeText("확인")
            let go = app.buttons["시작하기 →"]
            if go.waitForExistence(timeout: 5) { go.tap() }
        }
        XCTAssertTrue(app.buttons["시작하기"].waitForExistence(timeout: 20), "홈 진입 실패")
        sleep(1)
        snap("A_홈_버튼구성")

        // 부모 대시보드 → 게이트가 떠야 한다
        let parent = app.buttons["부모 대시보드"]
        XCTAssertTrue(parent.waitForExistence(timeout: 10))
        parent.tap()
        XCTAssertTrue(app.staticTexts["보호자 확인"].waitForExistence(timeout: 10),
                      "부모 게이트가 뜨지 않았다")
        sleep(1)
        snap("B_부모게이트")

        // 오답을 넣으면 문제가 바뀌고 통과하지 못해야 한다
        let answer = app.textFields.firstMatch
        if answer.waitForExistence(timeout: 5) {
            answer.tap(); answer.typeText("1")
            app.buttons["확인"].tap()
            sleep(1)
            XCTAssertTrue(app.staticTexts["보호자 확인"].exists, "오답인데 통과했다")
            snap("C_게이트_오답")
        }

        // 돌아가기
        if app.buttons["돌아가기"].exists { app.buttons["돌아가기"].tap() }
        sleep(1)

        // 가족 리더보드는 게이트 없이 바로 들어가야 한다
        let family = app.buttons["가족 리더보드"]
        XCTAssertTrue(family.waitForExistence(timeout: 10), "홈에 가족 리더보드 버튼이 없다")
        family.tap()
        sleep(3)
        XCTAssertFalse(app.staticTexts["보호자 확인"].exists, "가족 리더보드에 게이트가 붙었다")
        snap("D_가족리더보드")
    }
}
