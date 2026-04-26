import Foundation
import FirebaseFirestore

// 가족 그룹 저장소 (Firestore)
final class FamilyGroupRepository {
    private let db = Firestore.firestore()
    private let collection = "familyGroups"
    private let defaults = UserDefaults.standard
    private let groupIdKey = "family_group_id"

    var savedGroupId: String? {
        get { defaults.string(forKey: groupIdKey) }
        set { defaults.set(newValue, forKey: groupIdKey) }
    }

    // MARK: - 그룹 생성

    func createGroup(uid: String, nickname: String) async throws -> FamilyGroup {
        let code = FamilyGroup.generateCode()
        let docRef = db.collection(collection).document()
        let group = FamilyGroup(
            id: docRef.documentID,
            groupCode: code,
            memberIds: [uid],
            memberNames: [uid: nickname],
            scores: [uid: 0],
            createdAt: Date(),
            createdBy: uid
        )
        try await docRef.setData(encode(group))
        savedGroupId = docRef.documentID
        return group
    }

    // MARK: - 그룹 참여

    func joinGroup(code: String, uid: String, nickname: String) async throws -> FamilyGroup {
        let snapshot = try await db.collection(collection)
            .whereField("groupCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else {
            throw GroupError.notFound
        }

        let docRef = doc.reference
        try await docRef.updateData([
            "memberIds": FieldValue.arrayUnion([uid]),
            "memberNames.\(uid)": nickname,
            "scores.\(uid)": 0
        ])
        savedGroupId = doc.documentID
        return try decode(doc.data(), id: doc.documentID)
    }

    // MARK: - 리더보드 조회

    func fetchLeaderboard(groupId: String) async throws -> FamilyGroup {
        let doc = try await db.collection(collection).document(groupId).getDocument()
        guard let data = doc.data() else { throw GroupError.notFound }
        return try decode(data, id: doc.documentID)
    }

    // MARK: - 점수 업데이트

    func updateScore(groupId: String, uid: String, score: Int) async throws {
        let docRef = db.collection(collection).document(groupId)
        let doc = try await docRef.getDocument()
        if let existing = (doc.data()?["scores"] as? [String: Int])?[uid], existing >= score { return }
        try await docRef.updateData(["scores.\(uid)": score])
    }

    // MARK: - 그룹 탈퇴

    func leaveGroup(groupId: String, uid: String) async throws {
        let docRef = db.collection(collection).document(groupId)
        try await docRef.updateData([
            "memberIds": FieldValue.arrayRemove([uid]),
            "memberNames.\(uid)": FieldValue.delete(),
            "scores.\(uid)": FieldValue.delete()
        ])
        savedGroupId = nil
    }

    // MARK: - Helpers

    private func encode(_ group: FamilyGroup) -> [String: Any] {
        [
            "id": group.id,
            "groupCode": group.groupCode,
            "memberIds": group.memberIds,
            "memberNames": group.memberNames,
            "scores": group.scores,
            "createdAt": Timestamp(date: group.createdAt),
            "createdBy": group.createdBy
        ]
    }

    private func decode(_ data: [String: Any], id: String) throws -> FamilyGroup {
        guard let code = data["groupCode"] as? String,
              let memberIds = data["memberIds"] as? [String],
              let memberNames = data["memberNames"] as? [String: String],
              let scores = data["scores"] as? [String: Int],
              let createdBy = data["createdBy"] as? String,
              let ts = data["createdAt"] as? Timestamp else {
            throw GroupError.decodeFailed
        }
        return FamilyGroup(
            id: id,
            groupCode: code,
            memberIds: memberIds,
            memberNames: memberNames,
            scores: scores,
            createdAt: ts.dateValue(),
            createdBy: createdBy
        )
    }

    enum GroupError: LocalizedError {
        case notFound, decodeFailed
        var errorDescription: String? {
            switch self {
            case .notFound: return "그룹을 찾을 수 없습니다."
            case .decodeFailed: return "데이터를 불러오는 데 실패했습니다."
            }
        }
    }
}
