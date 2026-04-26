import Foundation

// 가족 그룹 모델
struct FamilyGroup: Codable, Identifiable {
    let id: String          // Firestore document ID
    let groupCode: String   // 6자리 초대 코드
    var memberIds: [String] // UserIdentity UID 목록
    var memberNames: [String: String]   // uid → nickname
    var scores: [String: Int]           // uid → 최고 점수
    let createdAt: Date
    var createdBy: String   // uid

    // 리더보드용 정렬된 멤버
    var sortedMembers: [(uid: String, name: String, score: Int)] {
        memberIds.compactMap { uid in
            guard let name = memberNames[uid] else { return nil }
            let score = scores[uid] ?? 0
            return (uid: uid, name: name, score: score)
        }
        .sorted { $0.score > $1.score }
    }

    static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
