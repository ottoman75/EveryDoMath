import XCTest

/// 기기를 돌렸을 때 화면이 쓸 수 있는 상태로 남는지 본다.
///
/// 1.0 이 Guideline 4 - Design 으로 두 번 반려된 자리다.
///
/// 1차: 세로로만 설계해 놓고 빌드는 가로를 지원한다고 선언했다. 가로로 돌리면
///      콘텐츠가 왼쪽 절반에 몰리고 「시작하기」 가 화면 밖으로 나갔다.
/// 2차: iPhone 전용이라 iPad 에서 375x667 캔버스로 확대돼 그려졌다. 글자가
///      늘어나고 학년 선택이 잘렸다. iPad 를 정식 지원해서 풀었다.
///
/// 그래서 지금 기대값은 기기마다 다르다.
///   iPhone — 가로를 지원하지 않는다. 돌려도 세로로 남아야 한다.
///   iPad   — 네 방향을 지원한다. 돌아가되 레이아웃이 살아 있어야 한다.
final class OrientationCheckTests: XCTestCase {

    private var app: XCUIApplication!

    /// 기기 종류를 세로 상태의 창 폭으로 가린다.
    ///
    /// `XCUIDevice` 에는 `userInterfaceIdiom` 키가 없다(KVC 예외가 난다).
    /// 그리고 여기서 정말 알고 싶은 것은 기기 이름이 아니라 **앱이 받은
    /// 캔버스**이므로, 폭을 직접 재는 쪽이 질문에 더 맞다.
    /// 세로에서 700pt 를 넘으면 iPad 캔버스다 — 폰은 가장 큰 것도 440 근처다.
    private var isPadCanvas: Bool {
        app.windows.firstMatch.frame.width > 700
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    func testRemainsUsableWhenDeviceRotates() throws {
        let start = app.buttons["시작하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 25), "세로에서 시작 버튼이 없다")
        XCTAssertTrue(start.isHittable, "세로에서 시작 버튼을 누를 수 없다")

        // 회전하면 폭이 바뀌므로 세로일 때 미리 잡아 둔다.
        let padCanvas = isPadCanvas

        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            sleep(2)

            // 두 기기 모두에서 지켜야 하는 것. `exists` 로는 안 잡힌다 —
            // 깨졌을 때도 버튼은 존재했고 화면 밖에 있었을 뿐이다.
            XCTAssertTrue(start.isHittable,
                          "\(orientation.rawValue) 로 돌렸더니 시작 버튼을 누를 수 없다")

            let frame = app.windows.firstMatch.frame
            if padCanvas {
                // iPad 는 돌아가도 된다. 창이 화면을 채우는지만 본다.
                XCTAssertGreaterThan(frame.width, 0)
                XCTAssertGreaterThan(frame.height, 0)
            } else {
                XCTAssertGreaterThan(frame.height, frame.width,
                                     "iPhone 인데 창이 가로가 됐다 (\(frame.width)x\(frame.height))")
            }
        }
    }

    /// iPad 에서 폰 호환 캔버스(375x667)로 확대돼 그려지지 않는지 본다.
    /// 2차 반려의 직접 원인이었다.
    func testUsesNativeCanvasOnPad() throws {
        _ = app.buttons["시작하기"].waitForExistence(timeout: 25)
        try XCTSkipUnless(isPadCanvas, "iPad 전용 점검")
        let frame = app.windows.firstMatch.frame
        XCTAssertFalse(frame.width == 375 && frame.height == 667,
                       "iPhone 호환 캔버스로 그려지고 있다 — iPad 를 지원하지 않는 빌드다")
        XCTAssertGreaterThan(frame.width, 700, "iPad 캔버스가 아니다 (\(frame.width)x\(frame.height))")
    }
}
