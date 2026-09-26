import Foundation

// 별명 검증
//
// 이 앱의 별명은 글로벌 리더보드에 올라가 다른 사용자에게 그대로 보인다.
// 즉 사용자 제작 콘텐츠(UGC)이고, 입력자는 대체로 초등학생이다.
// 두 가지를 막아야 한다.
//   1) 어린이가 실명·학교·전화번호를 적어 공개되는 것
//   2) 부적절한 표현이 다른 어린이에게 보이는 것
//
// 완전한 필터는 불가능하다. 여기서 거르지 못한 것은 신고 기능
// (ModerationRepository)으로 처리한다.
enum NicknameValidator {

    static let minLength = 2
    static let maxLength = 12

    enum Failure: Error, Equatable {
        case tooShort
        case tooLong
        case looksLikePersonalInfo
        case containsBannedWord

        var messageKey: String {
            switch self {
            case .tooShort:             return "nickname.error_too_short"
            case .tooLong:              return "nickname.error_too_long"
            case .looksLikePersonalInfo: return "nickname.error_personal_info"
            case .containsBannedWord:   return "nickname.error_banned_word"
            }
        }
    }

    /// 성공하면 저장에 쓸 정규화된 별명을 돌려준다.
    static func validate(_ raw: String) -> Result<String, Failure> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= minLength else { return .failure(.tooShort) }
        guard trimmed.count <= maxLength else { return .failure(.tooLong) }

        // 전화번호·생년월일처럼 보이는 숫자 나열을 막는다.
        if hasLongDigitRun(trimmed) { return .failure(.looksLikePersonalInfo) }

        if containsBannedWord(trimmed) { return .failure(.containsBannedWord) }

        return .success(trimmed)
    }

    // MARK: - Private

    /// 연속된 숫자가 4자리 이상이면 개인정보로 본다.
    private static func hasLongDigitRun(_ s: String) -> Bool {
        var run = 0
        for ch in s {
            if ch.isNumber {
                run += 1
                if run >= 4 { return true }
            } else {
                run = 0
            }
        }
        return false
    }

    /// 공백·특수문자를 끼워 넣어 우회하는 것을 막기 위해 먼저 정규화한다.
    /// 한글 음절도 alphanumerics 에 포함되므로 별도 범위 검사는 필요 없다.
    private static func normalize(_ s: String) -> String {
        String(String.UnicodeScalarView(
            s.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        ))
    }

    private static func containsBannedWord(_ s: String) -> Bool {
        let n = normalize(s)
        return bannedWords.contains { n.contains($0) }
    }

    // 부분 문자열로 검사하므로 짧고 흔한 단어(ass, sex 등)는 넣지 않는다.
    // "Cassie" 같은 멀쩡한 이름이 걸리는 오탐이 더 해롭기 때문이다.
    private static let bannedWords: Set<String> = [
        // 한국어
        "시발", "씨발", "씨팔", "시팔", "쓰발", "개새", "새끼", "병신", "븅신",
        "지랄", "좆", "존나", "죤나", "씹", "니미", "애미", "애비",
        "걸레", "창녀", "미친년", "미친놈", "꺼져", "죽어라", "자살", "강간",
        "자지", "보지", "섹스", "야동", "포르노",
        // 영어
        "fuck", "shit", "bitch", "asshole", "bastard", "dick", "cunt",
        "pussy", "penis", "vagina", "porn", "rape", "nigger", "faggot",
        "whore", "slut", "suicide", "kill you", "creampie"
    ]
}
