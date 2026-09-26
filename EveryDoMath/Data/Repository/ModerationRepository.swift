import Foundation
import FirebaseFirestore

// 리더보드 별명 신고 / 사용자 숨기기
//
// App Store 심사 가이드라인 1.2 는 사용자 제작 콘텐츠를 노출하는 앱에
// (a) 부적절한 콘텐츠 필터, (b) 신고 수단, (c) 차단 수단 을 요구한다.
// (a) 는 NicknameValidator 가, (b)(c) 는 여기가 맡는다.
//
// 차단은 기기 로컬에 둔다. 서버에 올려 봐야 신고자 본인에게만 적용되는
// 목록이고, 로컬이면 네트워크 없이도 즉시 반영된다.
final class ModerationRepository {
    static let shared = ModerationRepository()

    private let db = Firestore.firestore()
    private let reportsCollection = "reports"
    private let defaults = UserDefaults.standard
    private let blockedKey = "blocked_user_ids"

    private init() {}

    // MARK: - 신고

    enum Reason: String {
        case inappropriateName = "inappropriate_name"
        case other
    }

    enum ReportError: LocalizedError {
        case notSignedIn
        var errorDescription: String? { L("family.error_no_identity") }
    }

    /// 신고를 남긴다. 운영자는 Firebase 콘솔에서 reports 컬렉션을 확인한다.
    func report(userId: String, nickname: String, reason: Reason = .inappropriateName) async throws {
        guard let reporterId = UserIdentityRepository.shared.userId else {
            throw ReportError.notSignedIn
        }
        try await db.collection(reportsCollection).addDocument(data: [
            "reporterId": reporterId,
            "reportedUserId": userId,
            "reportedNickname": nickname,
            "reason": reason.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - 숨기기 (차단)

    var blockedUserIds: Set<String> {
        Set(defaults.stringArray(forKey: blockedKey) ?? [])
    }

    func block(userId: String) {
        var ids = blockedUserIds
        ids.insert(userId)
        defaults.set(Array(ids), forKey: blockedKey)
    }

    func unblock(userId: String) {
        var ids = blockedUserIds
        ids.remove(userId)
        defaults.set(Array(ids), forKey: blockedKey)
    }

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }
}
