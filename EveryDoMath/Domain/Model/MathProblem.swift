import Foundation

// MARK: - 입력 모드 (키패드 모드)
enum InputMode: String, Codable {
    case integer  // 정수: 1~6학년 기본
    case decimal  // 소수: 5~6학년 소수 문제 (. 키 추가)
    case fraction // 분수: 5~6학년 분수 문제 (/ 키 추가)
}

// MARK: - 정답 값 타입
enum AnswerValue: Codable, Equatable, Hashable {
    case integer(Int)
    case decimal(Double)                         // 소수 정답
    case fraction(numerator: Int, denominator: Int) // 분수 정답 (기약분수 기준)

    /// 사용자 입력 문자열과 정답 비교
    func matches(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        switch self {
        case .integer(let n):
            return Int(trimmed) == n

        case .decimal(let d):
            // 소수점 입력: "3.8" 또는 정수 "4"도 허용
            if let v = Double(trimmed) {
                return abs(v - d) < 0.0001
            }
            return false

        case .fraction(let num, let den):
            // "/" 구분자: "5/6", "10/12"(동치 허용), 정수 "2"(분모=1일 때)
            let parts = trimmed.split(separator: "/")
            if parts.count == 2,
               let n = Int(parts[0]),
               let d = Int(parts[1]),
               d != 0 {
                // 동치 분수 허용: 크로스 곱 비교
                return n * den == num * d
            } else if parts.count == 1, let n = Int(parts[0]) {
                return n == num && den == 1
            }
            return false
        }
    }

    /// 피드백에 표시할 정답 문자열
    var displayString: String {
        switch self {
        case .integer(let n): return "\(n)"
        case .decimal(let d):
            // 소수점 이하 불필요한 0 제거: 3.0 → "3", 3.8 → "3.8"
            if d == d.rounded() { return "\(Int(d))" }
            return String(format: "%.2f", d).replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        case .fraction(let num, let den):
            if den == 1 { return "\(num)" }
            return "\(num)/\(den)"
        }
    }
}

// MARK: - 수학 문제
struct MathProblem: Identifiable, Codable, Hashable {
    let id: UUID
    let grade: Grade
    let operation: MathOperation
    let inputMode: InputMode
    let displayString: String       // 화면에 표시되는 문제 텍스트
    let answerValue: AnswerValue    // 정답

    /// 정답 표시 문자열
    var answerDisplayString: String { answerValue.displayString }

    /// 입력값이 정답인지 확인
    func isCorrectAnswer(_ input: String) -> Bool {
        answerValue.matches(input)
    }

    // MARK: - 정수 문제 생성자 (기존 호환)
    init(operand1: Int, operand2: Int, operation: MathOperation, grade: Grade) {
        self.id = UUID()
        self.grade = grade
        self.operation = operation
        self.inputMode = .integer

        let symbol = operation.symbol
        self.displayString = "\(operand1) \(symbol) \(operand2) = ?"

        let answer: Int
        switch operation {
        case .addition:       answer = operand1 + operand2
        case .subtraction:    answer = operand1 - operand2
        case .multiplication: answer = operand1 * operand2
        case .division:       answer = operand1 / operand2
        }
        self.answerValue = .integer(answer)
    }

    // MARK: - 소수 문제 생성자
    init(decimal1: Double, decimal2: Double, operation: MathOperation, grade: Grade) {
        self.id = UUID()
        self.grade = grade
        self.operation = operation
        self.inputMode = .decimal

        let d1 = Self.formatDecimal(decimal1)
        let d2 = Self.formatDecimal(decimal2)
        self.displayString = "\(d1) \(operation.symbol) \(d2) = ?"

        let answer: Double
        switch operation {
        case .addition:       answer = decimal1 + decimal2
        case .subtraction:    answer = decimal1 - decimal2
        case .multiplication: answer = decimal1 * decimal2
        case .division:       answer = decimal1 / decimal2
        }
        self.answerValue = .decimal((answer * 100).rounded() / 100)
    }

    // MARK: - 분수 문제 생성자
    init(num1: Int, den1: Int, num2: Int, den2: Int, operation: MathOperation, grade: Grade) {
        self.id = UUID()
        self.grade = grade
        self.operation = operation
        self.inputMode = .fraction

        let f1 = Self.formatFraction(num1, den1)
        let f2 = Self.formatFraction(num2, den2)
        self.displayString = "\(f1) \(operation.symbol) \(f2) = ?"

        var answerNum: Int
        var answerDen: Int
        switch operation {
        case .addition:
            answerNum = num1 * den2 + num2 * den1
            answerDen = den1 * den2
        case .subtraction:
            answerNum = num1 * den2 - num2 * den1
            answerDen = den1 * den2
        case .multiplication:
            answerNum = num1 * num2
            answerDen = den1 * den2
        case .division:
            answerNum = num1 * den2
            answerDen = den1 * num2
        }
        let g = Self.gcd(abs(answerNum), abs(answerDen))
        self.answerValue = .fraction(numerator: answerNum / g, denominator: answerDen / g)
    }

    // MARK: - Helpers

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }

    static func formatDecimal(_ d: Double) -> String {
        if d == d.rounded() { return "\(Int(d))" }
        return String(format: "%g", d)
    }

    static func formatFraction(_ num: Int, _ den: Int) -> String {
        if den == 1 { return "\(num)" }
        return "\(num)/\(den)"
    }
}
