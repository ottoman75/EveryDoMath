import Foundation

// 잠긴 학년에 대한 1회성 무료 체험(Trial) 관리
// - 무료 학년(grade1, grade2)은 trial 대상이 아님
// - 학년별로 1회 체험 가능, 사용 후 UserDefaults에 마킹
enum TrialManager {
    static let trialQuestionCount = 5

    /// 해당 학년의 trial이 가능한지 확인
    /// - 무료 학년은 false (이미 잠금 해제)
    /// - 이미 사용한 학년은 false
    static func isTrialAvailable(for grade: Grade) -> Bool {
        guard !grade.isFree else { return false }
        return !UserDefaults.standard.bool(forKey: trialKey(grade))
    }

    /// 해당 학년의 trial을 사용 처리 (영구 마킹)
    static func markTrialUsed(for grade: Grade) {
        UserDefaults.standard.set(true, forKey: trialKey(grade))
    }

    private static func trialKey(_ grade: Grade) -> String {
        "trial_used_grade_\(grade.rawValue)"
    }
}
