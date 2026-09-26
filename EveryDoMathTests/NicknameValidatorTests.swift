import Testing
@testable import EveryDoMath

/// 별명은 공개 리더보드에 그대로 노출되므로, 통과 기준이 코드와 함께
/// 흔들리지 않도록 고정한다.
struct NicknameValidatorTests {

    private func failure(_ s: String) -> NicknameValidator.Failure? {
        if case .failure(let f) = NicknameValidator.validate(s) { return f }
        return nil
    }

    private func success(_ s: String) -> String? {
        if case .success(let v) = NicknameValidator.validate(s) { return v }
        return nil
    }

    @Test("평범한 별명은 통과하고 앞뒤 공백은 정리된다")
    func acceptsOrdinaryNicknames() {
        #expect(success("수학왕") == "수학왕")
        #expect(success("  별똥별  ") == "별똥별")
        #expect(success("MathHero") == "MathHero")
    }

    @Test("길이 범위를 벗어나면 거부한다")
    func rejectsOutOfRangeLength() {
        #expect(failure("가") == .tooShort)
        #expect(failure("") == .tooShort)
        #expect(failure(String(repeating: "가", count: 13)) == .tooLong)
        // 경계값은 통과해야 한다
        #expect(success("가나") == "가나")
        #expect(success(String(repeating: "가", count: 12)) != nil)
    }

    @Test("전화번호처럼 보이는 숫자 나열을 거부한다")
    func rejectsLongDigitRuns() {
        #expect(failure("홍길동0101") == .looksLikePersonalInfo)
        #expect(failure("2015년생") == .looksLikePersonalInfo)
        // 짧은 숫자는 허용한다 — "수학왕123" 같은 별명까지 막을 이유는 없다
        #expect(success("수학왕123") == "수학왕123")
    }

    @Test("부적절한 표현을 거부한다")
    func rejectsBannedWords() {
        #expect(failure("병신") == .containsBannedWord)
        #expect(failure("FuckYou") == .containsBannedWord)
    }

    @Test("특수문자로 우회해도 거부한다")
    func rejectsObfuscatedBannedWords() {
        // 정규화가 공백과 특수문자를 걷어내므로 걸려야 한다
        #expect(failure("병 신") == .containsBannedWord)
        #expect(failure("f.u.c.k") == .containsBannedWord)
    }

    @Test("흔한 이름이 오탐으로 걸리지 않는다")
    func doesNotFlagOrdinaryNames() {
        // 짧고 흔한 단어를 금칙어에 넣지 않기로 한 결정을 고정한다
        #expect(success("Cassie") == "Cassie")
        #expect(success("Passion") == "Passion")
    }
}
