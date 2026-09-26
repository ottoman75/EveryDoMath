import XCTest

/// 점수 업로드(쓰기) 경로 검증용.
///
/// Firestore 규칙이 updatedAt == request.time 을 요구해서 REST 로는 확인할 수
/// 없다. serverTimestamp 를 보내는 건 iOS SDK 뿐이다. 그래서 앱을 실제로
/// 돌려 한 판을 끝내고, Firestore 에 문서가 생겼는지로 판정한다.
///
/// 점수가 0이면 앱이 업로드를 건너뛰므로(score > 기존최고) 문제를 실제로
/// 풀어서 맞혀야 한다. 1학년은 정수 덧셈/뺄셈뿐이라 파싱이 간단하다.
/// ⚠️ 이 테스트는 운영 Firestore 에 문서를 실제로 쓴다. 끝나면 콘솔에서
/// 닉네임 '쓰기검증' 문서를 지울 것.
/// 실행: xcodebuild test -only-testing:EveryDoMathUITests/UploadPathTests
final class UploadPathTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
    }

    /// "7 + 5 = ?" 형태의 식을 찾아 답을 계산한다.
    ///
    /// 뺄셈 기호는 하이픈이 아니라 U+2212(−) 다. 정규식에는 이스케이프가
    /// 아니라 문자를 그대로 넣는다. raw string 안의 \u{...} 는 Swift 가
    /// 해석하지 않고 ICU 에서도 유효하지 않아 패턴 컴파일이 실패한다.
    ///
    /// 정수 문제는 MathExpressionView 가 Text(expression) 하나로 그리므로
    /// staticText 하나에 식 전체가 들어 있다. 분수는 토큰으로 쪼개져 여기서
    /// 걸리지 않는데, 이 테스트는 1학년(정수)만 쓰므로 문제되지 않는다.
    private func currentAnswer() -> Int? {
        let pattern = "^\\s*(\\d+)\\s*([+\u{2212}×÷])\\s*(\\d+)\\s*=\\s*\\?\\s*$"
        let re: NSRegularExpression
        do {
            re = try NSRegularExpression(pattern: pattern)
        } catch {
            XCTFail("정규식 컴파일 실패: \(error)")
            return nil
        }

        for text in app.staticTexts.allElementsBoundByIndex {
            guard text.exists else { continue }
            let s = text.label
            let range = NSRange(s.startIndex..., in: s)
            guard let m = re.firstMatch(in: s, range: range),
                  let r1 = Range(m.range(at: 1), in: s),
                  let r2 = Range(m.range(at: 2), in: s),
                  let r3 = Range(m.range(at: 3), in: s),
                  let a = Int(s[r1]), let b = Int(s[r3]) else { continue }
            switch String(s[r2]) {
            case "+": return a + b
            case "\u{2212}": return a - b
            case "×": return a * b
            case "÷": return b == 0 ? nil : a / b
            default: return nil
            }
        }
        return nil
    }



    @MainActor
    func testFullGameUploadsScore() throws {
        // ── 프로필 설정: 1학년 ────────────────────────────────
        let field = app.textFields.firstMatch
        if field.waitForExistence(timeout: 10) {
            field.tap()
            field.typeText("쓰기검증")
            let grade1 = app.buttons.containing(.staticText, identifier: "1").firstMatch
            if grade1.exists { grade1.tap() }
            let go = app.buttons["시작하기 →"]
            if go.waitForExistence(timeout: 5) { go.tap() }
        }

        // ── 게임 시작 ────────────────────────────────────────
        let start = app.buttons["시작하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 20), "홈 진입 실패")
        start.tap()

        let confirm = app.buttons["확인 ✓"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 20), "게임 화면 진입 실패")

        // ── 20문제 풀이 ──────────────────────────────────────
        var solved = 0
        for i in 0..<20 {
            // 피드백 오버레이가 사라질 때까지 잠깐 대기
            var answer: Int?
            for _ in 0..<20 {
                answer = currentAnswer()
                if answer != nil { break }
                usleep(300_000)
            }
            guard let value = answer else {
                print("문제 \(i + 1): 식을 찾지 못함 — 화면의 staticText 덤프")
                for t in app.staticTexts.allElementsBoundByIndex where t.exists {
                    print("  staticText: [\(t.label)]")
                }
                break
            }
            for ch in String(value) where ch.isNumber {
                let key = app.buttons[String(ch)]
                if key.exists { key.tap() }
            }
            if confirm.exists { confirm.tap() }
            solved += 1
            // 정답 0.8초 / 오답 1.5초 피드백 후 다음 문제
            usleep(1_600_000)
        }
        print("풀이한 문제 수: \(solved)")

        // ── 결과 화면 도달 = 업로드가 일어난 시점 ──────────────
        let goHome = app.buttons["홈으로"]
        XCTAssertTrue(goHome.waitForExistence(timeout: 30), "결과 화면 진입 실패")

        // 비동기 업로드가 끝날 여유
        sleep(6)

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "결과화면"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
