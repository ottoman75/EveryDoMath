import Testing
import Foundation
@testable import EveryDoMath

/// 문제 생성기는 난수를 쓰므로 한 번 돌려보는 것으로는 부족하다.
/// 충분히 많이 뽑아 값의 범위와 성질을 확인한다.
struct ProblemGeneratorTests {

    /// 소수 모드 나눗셈 문제만 골라낸다
    private func decimalDivisions(grade: Grade, batches: Int = 60) -> [MathProblem] {
        (0..<batches)
            .flatMap { _ in ProblemGenerator.generate(grade: grade, count: 20) }
            .filter { $0.operation == .division && $0.inputMode == .decimal }
    }

    /// "4.8 ÷ 4 = ?" 에서 피제수와 제수를 뽑는다
    private func operands(_ p: MathProblem) -> (Double, Double)? {
        let parts = p.displayString
            .replacingOccurrences(of: "= ?", with: "")
            .components(separatedBy: MathOperation.division.symbol)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let a = Double(parts[0]), let b = Double(parts[1]) else { return nil }
        return (a, b)
    }

    // MARK: - 5학년: 소수 ÷ 자연수

    @Test("5학년 나눗셈은 실제로 소수가 등장해야 한다")
    func grade5DivisionIsActuallyDecimal() {
        let problems = decimalDivisions(grade: .grade5)
        #expect(!problems.isEmpty, "소수 나눗셈 문제가 한 건도 생성되지 않았다")

        // 회귀 방지: 예전에는 `* 10` 과 `/ 10.0` 이 상쇄돼 정수 ÷ 정수만 나왔다.
        // 피제수 또는 정답 중 하나는 반드시 소수여야 한다.
        for p in problems {
            guard let (dividend, _) = operands(p) else { continue }
            guard case .decimal(let answer) = p.answerValue else {
                Issue.record("소수 문제인데 정답이 소수 타입이 아니다: \(p.displayString)")
                continue
            }
            let dividendIsDecimal = abs(dividend - dividend.rounded()) > 1e-9
            let answerIsDecimal   = abs(answer - answer.rounded()) > 1e-9
            #expect(dividendIsDecimal || answerIsDecimal,
                    "정수 나눗셈이 소수 문제로 나왔다: \(p.displayString)")
        }
    }

    @Test("5학년 제수는 2~8 자연수다")
    func grade5DivisorIsWholeNumber() {
        for p in decimalDivisions(grade: .grade5) {
            guard let (_, divisor) = operands(p) else { continue }
            #expect(abs(divisor - divisor.rounded()) < 1e-9, "제수가 자연수가 아니다: \(p.displayString)")
            #expect(divisor >= 2 && divisor <= 8, "제수가 범위를 벗어났다: \(p.displayString)")
        }
    }

    @Test("5학년 몫은 1.1~4.9 범위이고 소수 한 자리다")
    func grade5QuotientStaysInRange() {
        for p in decimalDivisions(grade: .grade5) {
            guard case .decimal(let answer) = p.answerValue else { continue }
            #expect(answer >= 1.1 - 1e-9 && answer <= 4.9 + 1e-9, "몫이 범위를 벗어났다: \(p.displayString)")
            // 소수 한 자리 — 10을 곱하면 정수여야 한다
            #expect(abs(answer * 10 - (answer * 10).rounded()) < 1e-6,
                    "몫이 소수 한 자리가 아니다: \(p.displayString) → \(answer)")
        }
    }

    // MARK: - 6학년: 소수 ÷ 소수

    @Test("6학년 나눗셈의 몫은 2~5 정수다")
    func grade6QuotientIsSmallInteger() {
        let problems = decimalDivisions(grade: .grade6)
        #expect(!problems.isEmpty)
        for p in problems {
            guard case .decimal(let answer) = p.answerValue else { continue }
            #expect(abs(answer - answer.rounded()) < 1e-4, "몫이 정수가 아니다: \(p.displayString)")
            #expect(answer >= 2 && answer <= 5, "몫이 2~5 범위를 벗어났다: \(p.displayString)")
        }
    }

    @Test("6학년 제수는 1.2~1.9 범위의 소수다")
    func grade6DivisorStaysInRange() {
        for p in decimalDivisions(grade: .grade6) {
            guard let (_, divisor) = operands(p) else { continue }
            #expect(divisor >= 1.2 - 1e-9 && divisor <= 1.9 + 1e-9,
                    "제수가 범위를 벗어났다: \(p.displayString)")
            // 회귀 방지: 제수가 2.0 이면 피제수도 정수가 돼 '소수 ÷ 소수' 가 아니게 된다
            #expect(abs(divisor - divisor.rounded()) > 1e-9,
                    "제수가 정수라 소수 나눗셈이 아니다: \(p.displayString)")
        }
    }

    // MARK: - 공통

    @Test("소수 나눗셈의 정답은 표시된 식과 일치한다")
    func answerMatchesDisplayedExpression() {
        for grade in [Grade.grade5, .grade6] {
            for p in decimalDivisions(grade: grade, batches: 30) {
                guard let (a, b) = operands(p),
                      case .decimal(let answer) = p.answerValue else { continue }
                #expect(abs(a / b - answer) < 0.01, "식과 정답이 어긋난다: \(p.displayString) → \(answer)")
            }
        }
    }

    @Test("정답 문자열을 그대로 입력하면 정답으로 인정된다")
    func answerDisplayStringIsAccepted() {
        for grade in [Grade.grade5, .grade6] {
            for p in decimalDivisions(grade: grade, batches: 20) {
                #expect(p.isCorrectAnswer(p.answerDisplayString),
                        "정답 표기를 입력했는데 오답 처리됐다: \(p.displayString) → \(p.answerDisplayString)")
            }
        }
    }
}
