import XCTest

/// 기기를 돌려도 앱이 세로로 남아 있는지 본다.
///
/// 1.0 이 Guideline 4 - Design 으로 반려된 원인이 여기였다. 빌드 설정이
/// 가로 두 방향을 지원한다고 선언해 뒀는데 화면은 전부 세로로만 설계돼 있어서,
/// 가로로 돌리면 콘텐츠가 왼쪽 절반에 몰리고 「시작하기」 가 화면 밖으로
/// 나갔다. 첫 화면을 넘어갈 수조차 없는 상태였다.
/// 심사는 iPad Air 에서 이뤄졌다 — iPad 는 가로로 들고 보는 일이 많다.
///
/// 고친 방법은 반응형 레이아웃이 아니라 세로 고정이다
/// (INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone).
/// 이 앱은 한 손으로 숫자 패드를 누르는 앱이라 가로를 쓸 이유가 없다.
final class OrientationCheckTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    /// 가로로 돌려도 첫 화면의 시작 버튼을 누를 수 있어야 한다.
    ///
    /// `exists` 로는 부족하다. 깨졌을 때도 요소는 존재했고, 화면 밖에 있어서
    /// 누를 수 없었을 뿐이다. `isHittable` 로 봐야 그 차이가 드러난다.
    func testStaysPortraitWhenDeviceRotates() throws {
        let start = app.buttons["시작하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 20), "세로에서 시작 버튼이 없다")
        XCTAssertTrue(start.isHittable, "세로에서 시작 버튼을 누를 수 없다")

        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            sleep(2)

            XCTAssertTrue(start.isHittable,
                          "기기를 \(orientation.rawValue) 로 돌렸더니 시작 버튼을 누를 수 없다 — 앱이 같이 돌아갔다")

            // 앱 창이 세로 비율을 유지하는지 직접 본다.
            let frame = app.windows.firstMatch.frame
            XCTAssertGreaterThan(frame.height, frame.width,
                                 "기기를 돌렸을 때 앱 창이 가로가 됐다 (\(frame.width)x\(frame.height))")
        }
    }
}
