import Foundation

// 기기별 고유 사용자 ID 관리 (로그인 없이 UUID 사용)
final class UserIdentityRepository {
    static let shared = UserIdentityRepository()

    private let defaults = UserDefaults.standard
    private let key = "user_device_uuid"

    private init() {}

    /// 기기 고유 UUID (최초 실행 시 생성, 이후 고정)
    var userId: String {
        if let existing = defaults.string(forKey: key) {
            return existing
        }
        let newId = UUID().uuidString
        defaults.set(newId, forKey: key)
        return newId
    }
}
