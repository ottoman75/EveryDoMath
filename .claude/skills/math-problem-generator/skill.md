---
name: math-problem-generator
description: "초등학교 1~6학년 수준의 수학 문제를 학년별로 생성하는 ProblemGenerator Swift 구현 가이드. 학년별 연산 범위, 난이도 조절, 분수/소수 처리 방법 포함. EveryDoMath 앱의 문제 출제 로직 구현 시 반드시 이 스킬을 사용할 것."
---

# 수학 문제 생성기 구현 가이드

## 학년별 문제 유형 명세

### 1학년 (Grade 1)
- 연산: 덧셈, 뺄셈
- 범위: 0-20 (결과값 포함)
- 형식: `a + b = ?`, `a - b = ?` (b ≤ a)
- 예시: `7 + 5 = ?`, `12 - 4 = ?`

### 2학년 (Grade 2)
- 연산: 덧셈, 뺄셈 (두 자리), 곱셈 2-5단
- 범위: 덧뺄셈 1-100, 곱셈 2-5단
- 형식: `a + b = ?`, `a × b = ?` (b ∈ 2,3,4,5)
- 예시: `34 + 27 = ?`, `3 × 4 = ?`

### 3학년 (Grade 3)
- 연산: 곱셈 전체(2-9단), 나눗셈 기초, 세 자리 덧뺄셈
- 범위: 곱셈 1-9, 나눗셈 (나머지 없는 것)
- 예시: `7 × 8 = ?`, `24 ÷ 6 = ?`, `245 + 137 = ?`

### 4학년 (Grade 4)
- 연산: 두 자리 곱셈, 나눗셈(나머지 있음), 혼합 연산
- 범위: 두 자리×한 자리, 두 자리÷한 자리
- 예시: `24 × 7 = ?`, `75 ÷ 8 = 9 ... ?`

### 5학년 (Grade 5)
- 연산: 분수 덧셈/뺄셈(동분모/이분모), 소수 덧셈/뺄셈
- 예시: `1/2 + 1/3 = ?`, `3.14 + 2.86 = ?`

### 6학년 (Grade 6)
- 연산: 분수 곱셈/나눗셈, 소수 곱셈, 혼합계산
- 예시: `2/3 × 3/4 = ?`, `1.5 × 2.4 = ?`

## Swift 구현 구조

```swift
struct MathProblem {
    let id: UUID
    let operand1: Double
    let operand2: Double
    let operation: MathOperation
    let correctAnswer: Double
    let displayString: String
    let answerDisplayString: String  // 분수 표시용
    let grade: Grade
}

enum MathOperation: String, CaseIterable {
    case addition = "+"
    case subtraction = "-"
    case multiplication = "×"
    case division = "÷"
}

class ProblemGenerator {
    static func generate(grade: Grade, count: Int = 20) -> [MathProblem]
    static func generateOne(grade: Grade) -> MathProblem
    private static func generateForGrade1() -> MathProblem
    // ... 학년별 private 메서드
}
```

## 분수 처리 방법
```swift
struct Fraction {
    let numerator: Int
    let denominator: Int
    
    var simplified: Fraction { /* 최대공약수로 약분 */ }
    var displayString: String { "\(numerator)/\(denominator)" }
    var doubleValue: Double { Double(numerator) / Double(denominator) }
}
```

## 정답 검증
- 정수 문제: 정확히 일치
- 소수 문제: 소수점 2자리까지 비교 (abs(input - answer) < 0.01)
- 분수 문제: 약분 후 비교

## 문제 생성 원칙
1. 항상 양수 결과 (뺄셈: operand1 ≥ operand2)
2. 나눗셈: 나머지 없는 것 우선 (4학년 이하)
3. 같은 문제 연속 등장 방지 (직전 문제와 비교)
4. 학년 적정 난이도 범위 엄수
