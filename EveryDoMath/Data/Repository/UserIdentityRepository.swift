import Foundation
import FirebaseAuth

// Firebase 익명 인증 기반 사용자 식별자
//
// 예전에는 기기에서 생성한 UUID 를 UserDefaults 에 넣어 썼다. 그 값은 앱이
// 마음대로 정하는 문자열이라 서버가 검증할 방법이 없었고, Firestore 규칙도
// "데이터의 모양"만 볼 수 있을 뿐 "누가 보냈는지"는 확인할 수 없었다.
// 그래서 남의 userId 를 알아내면 그 사람 리더보드 기록을 덮어쓸 수 있었다.
//
// 익명 인증의 uid 는 Firebase 가 발급하고 요청마다 토큰으로 증명되므로,
// 규칙에서 request.auth.uid == userId 로 신원을 강제할 수 있다.
//
// 주의: Firebase 콘솔에서 Authentication > Sign-in method > 익명 을
// 활성화해야 동작한다.
final class UserIdentityRepository {
    static let shared = UserIdentityRepository()

    private init() {}

    /// 현재 사용자 uid. 로그인 완료 전에는 nil 이다.
    var userId: String? {
        Auth.auth().currentUser?.uid
    }

    /// 앱 시작 시 1회 호출한다.
    /// 세션은 키체인에 보존되므로 두 번째 실행부터는 네트워크 없이 복원된다.
    @discardableResult
    func signInIfNeeded() async -> String? {
        if let uid = Auth.auth().currentUser?.uid { return uid }
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("✅ [UserIdentity] 익명 로그인 완료")
            return result.user.uid
        } catch {
            print("❌ [UserIdentity] 익명 로그인 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
