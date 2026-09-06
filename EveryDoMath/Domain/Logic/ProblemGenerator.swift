import Foundation

// 학년별 수학 문제 생성기
struct ProblemGenerator {

    /// 해당 학년에 맞는 count개 문제 생성 (연산 고르게 분배, 연속 동일 문제 방지)
    static func generate(grade: Grade, count: Int = 20) -> [MathProblem] {
        var problems: [MathProblem] = []
        let operationQueue = makeOperationQueue(grade: grade, count: count)

        for i in 0..<count {
            let op = operationQueue[i]
            var problem = generateSingle(grade: grade, operation: op)

            var retry = 0
            while retry < 10, let last = problems.last,
                  last.displayString == problem.displayString {
                problem = generateSingle(grade: grade, operation: op)
                retry += 1
            }
            problems.append(problem)
        }
        return problems
    }

    // MARK: - 연산 분배

    private static func makeOperationQueue(grade: Grade, count: Int) -> [MathOperation] {
        let ops = grade.allowedOperations
        var result: [MathOperation] = []
        let base = count / ops.count
        let remainder = count % ops.count
        for (i, op) in ops.enumerated() {
            result.append(contentsOf: Array(repeating: op, count: base + (i < remainder ? 1 : 0)))
        }
        return result.shuffled()
    }

    // MARK: - 학년별 라우터

    private static func generateSingle(grade: Grade, operation: MathOperation) -> MathProblem {
        switch grade {
        case .grade1: return generateGrade1(operation: operation)
        case .grade2: return generateGrade2(operation: operation)
        case .grade3: return generateGrade3(operation: operation)
        case .grade4: return generateGrade4(operation: operation)
        case .grade5: return generateGrade5(operation: operation)
        case .grade6: return generateGrade6(operation: operation)
        }
    }

    // MARK: - 1학년: +, - (1~20, 결과>=0)

    private static func generateGrade1(operation: MathOperation) -> MathProblem {
        switch operation {
        case .addition:
            let a = Int.random(in: 1...10)
            let b = Int.random(in: 1...(20 - a))
            return MathProblem(operand1: a, operand2: b, operation: .addition, grade: .grade1)
        default:
            let a = Int.random(in: 2...20)
            let b = Int.random(in: 1...a)
            return MathProblem(operand1: a, operand2: b, operation: .subtraction, grade: .grade1)
        }
    }

    // MARK: - 2학년: +, - (1~100)

    private static func generateGrade2(operation: MathOperation) -> MathProblem {
        switch operation {
        case .addition:
            let a = Int.random(in: 10...50)
            let b = Int.random(in: 10...(100 - a))
            return MathProblem(operand1: a, operand2: b, operation: .addition, grade: .grade2)
        default:
            let a = Int.random(in: 20...100)
            let b = Int.random(in: 1...a)
            return MathProblem(operand1: a, operand2: b, operation: .subtraction, grade: .grade2)
        }
    }

    // MARK: - 3학년: +, -, × (×: 1~9단)

    private static func generateGrade3(operation: MathOperation) -> MathProblem {
        switch operation {
        case .addition:
            let a = Int.random(in: 100...500)
            let b = Int.random(in: 100...500)
            return MathProblem(operand1: a, operand2: b, operation: .addition, grade: .grade3)
        case .subtraction:
            let a = Int.random(in: 200...999)
            let b = Int.random(in: 100...a)
            return MathProblem(operand1: a, operand2: b, operation: .subtraction, grade: .grade3)
        default: // multiplication
            let a = Int.random(in: 2...9)
            let b = Int.random(in: 2...9)
            return MathProblem(operand1: a, operand2: b, operation: .multiplication, grade: .grade3)
        }
    }

    // MARK: - 4학년: +, -, ×, ÷ (2자리×1자리, 나머지없는 나눗셈)

    private static func generateGrade4(operation: MathOperation) -> MathProblem {
        switch operation {
        case .addition:
            let a = Int.random(in: 100...999)
            let b = Int.random(in: 100...999)
            return MathProblem(operand1: a, operand2: b, operation: .addition, grade: .grade4)
        case .subtraction:
            let a = Int.random(in: 200...999)
            let b = Int.random(in: 100...a)
            return MathProblem(operand1: a, operand2: b, operation: .subtraction, grade: .grade4)
        case .multiplication:
            let a = Int.random(in: 10...99)
            let b = Int.random(in: 2...9)
            return MathProblem(operand1: a, operand2: b, operation: .multiplication, grade: .grade4)
        case .division:
            let divisor = Int.random(in: 2...9)
            let quotient = Int.random(in: 2...20)
            return MathProblem(operand1: divisor * quotient, operand2: divisor, operation: .division, grade: .grade4)
        }
    }

    // MARK: - 5학년: 분수 덧셈/뺄셈, 소수 덧셈/뺄셈 (혼합)

    private static func generateGrade5(operation: MathOperation) -> MathProblem {
        // 분수/소수를 반반씩 섞어서 출제
        let useFraction = Bool.random()

        if useFraction {
            return generateFractionProblem(operation: operation, grade: .grade5)
        } else {
            return generateDecimalProblem(operation: operation, grade: .grade5)
        }
    }

    // MARK: - 6학년: 분수 곱셈/나눗셈, 소수 곱셈/나눗셈

    private static func generateGrade6(operation: MathOperation) -> MathProblem {
        let useFraction = Bool.random()

        if useFraction {
            return generateFractionProblem(operation: operation, grade: .grade6)
        } else {
            return generateDecimalProblem(operation: operation, grade: .grade6)
        }
    }

    // MARK: - 분수 문제 생성

    private static func generateFractionProblem(operation: MathOperation, grade: Grade) -> MathProblem {
        let denominators = [2, 3, 4, 5, 6, 8, 9, 10]

        switch operation {
        case .addition, .subtraction:
            // 이분모 분수 덧셈/뺄셈: a/b ± c/d
            let den1 = denominators.randomElement()!
            let den2 = denominators.filter { $0 != den1 }.randomElement()!
            let num1 = Int.random(in: 1...(den1 - 1))
            var num2 = Int.random(in: 1...(den2 - 1))

            // 뺄셈: num1/den1 > num2/den2 보장 (결과 양수)
            // 조건: num2 < num1*den2/den1 → maxNum2 = (num1*den2 - 1) / den1 (정수 나눗셈)
            if operation == .subtraction {
                let maxNum2 = (num1 * den2 - 1) / den1
                if maxNum2 < 1 {
                    // 이 분모 조합으로는 양수 결과를 만들 수 없으므로 재시도
                    return generateFractionProblem(operation: operation, grade: grade)
                }
                if num2 * den1 >= num1 * den2 {
                    num2 = Int.random(in: 1...maxNum2)
                }
            }
            return MathProblem(num1: num1, den1: den1, num2: num2, den2: den2, operation: operation, grade: grade)

        case .multiplication:
            // 진분수 곱셈: a/b × c/d
            let den1 = denominators.randomElement()!
            let den2 = denominators.randomElement()!
            let num1 = Int.random(in: 1...(den1 - 1))
            let num2 = Int.random(in: 1...(den2 - 1))
            return MathProblem(num1: num1, den1: den1, num2: num2, den2: den2, operation: .multiplication, grade: grade)

        case .division:
            // 분수 ÷ 자연수: a/b ÷ n (결과가 깔끔하게)
            let den1 = denominators.randomElement()!
            let divisor = Int.random(in: 2...6)
            // num1이 divisor의 배수이면 깔끔한 정수 분자 → 아니어도 분수로 처리
            let num1 = Int.random(in: 1...(den1 - 1))
            return MathProblem(num1: num1, den1: den1, num2: 1, den2: divisor, operation: .division, grade: grade)
        }
    }

    // MARK: - 소수 문제 생성

    private static func generateDecimalProblem(operation: MathOperation, grade: Grade) -> MathProblem {
        switch operation {
        case .addition:
            // 소수 한 자리 덧셈
            let a = Double(Int.random(in: 10...90)) / 10.0   // 1.0~9.0
            let b = Double(Int.random(in: 10...90)) / 10.0
            return MathProblem(decimal1: a, decimal2: b, operation: .addition, grade: grade)

        case .subtraction:
            // 소수 한 자리 뺄셈 (결과 양수)
            let a = Double(Int.random(in: 30...90)) / 10.0
            let b = Double(Int.random(in: 10...Int(a * 10) - 1)) / 10.0
            return MathProblem(decimal1: a, decimal2: b, operation: .subtraction, grade: grade)

        case .multiplication:
            if grade == .grade5 {
                // 소수 × 자연수: 1.5 × 4
                let a = Double(Int.random(in: 11...99)) / 10.0
                let b = Double(Int.random(in: 2...9))
                return MathProblem(decimal1: a, decimal2: b, operation: .multiplication, grade: grade)
            } else {
                // 소수 × 소수: 1.5 × 2.4 (6학년)
                let a = Double(Int.random(in: 11...50)) / 10.0
                let b = Double(Int.random(in: 11...50)) / 10.0
                return MathProblem(decimal1: a, decimal2: b, operation: .multiplication, grade: grade)
            }

        case .division:
            if grade == .grade5 {
                // 소수 ÷ 자연수: 4.8 ÷ 4 = 1.2 (5학년, 몫이 소수)
                // `* 10` 뒤에 `/ 10.0` 을 하면 서로 상쇄돼 피제수가 정수가 된다.
                // 몫을 1/10 단위로 뽑아 피제수가 소수 한 자리를 갖도록 한다.
                // 몫의 소수부를 1...9 로 뽑아 X.0 을 배제한다. 그렇지 않으면
                // 몫이 2.0/3.0/4.0 일 때 피제수도 정수가 돼 정수 나눗셈이 나온다.
                let divisor = Int.random(in: 2...8)
                let quotientTenths = Int.random(in: 1...4) * 10 + Int.random(in: 1...9)  // 1.1 ~ 4.9
                let dividend = Double(divisor * quotientTenths) / 10.0
                return MathProblem(decimal1: dividend, decimal2: Double(divisor), operation: .division, grade: grade)
            } else {
                // 소수 ÷ 소수: 3.6 ÷ 1.2 (6학년, 결과 정수) — 나눗수 1.2~1.9, 몫 2~5로 제한
                // 2.0 을 빼는 이유는 제수가 정수가 되면 '소수 ÷ 소수' 가 아니게 되기 때문이다
                // (2.0 이면 피제수도 정수가 돼 10 ÷ 2 같은 문제가 나온다).
                let result = Int.random(in: 2...5)
                let b = Double(Int.random(in: 12...19)) / 10.0
                let a = (b * Double(result) * 10).rounded() / 10.0
                return MathProblem(decimal1: a, decimal2: b, operation: .division, grade: grade)
            }
        }
    }

    // MARK: - GCD 헬퍼

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        b == 0 ? a : gcd(b, a % b)
    }
}
