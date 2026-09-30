import Foundation
import FirebaseFirestore

// Firestore 기반 글로벌 리더보드 저장소
// 유저당 문서 1개 (documentID = userId) — 최고 점수만 유지
final class RemoteLeaderboardRepository {
    static let shared = RemoteLeaderboardRepository()

    private let db = Firestore.firestore()
    private let collection = "leaderboard"

    private init() {}

    // MARK: - 점수 업로드

    /// 현재 점수가 Firestore에 저장된 최고 점수보다 높을 때만 업데이트
    func uploadScore(nickname: String, grade: Grade, score: Int, gameGrade: GameGrade, correctCount: Int) {
        guard let userId = UserIdentityRepository.shared.userId else {
            print("ℹ️ [RemoteLeaderboard] 로그인 전이라 업로드를 건너뛴다")
            return
        }
        let docRef = db.collection(collection).document(userId)

        db.runTransaction({ transaction, errorPointer -> Any? in
            let existing: DocumentSnapshot
            do {
                existing = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let currentBest = existing.data()?["score"] as? Int ?? 0
            guard score > currentBest else {
                print("ℹ️ [RemoteLeaderboard] 기존 최고 점수(\(currentBest))보다 낮아 업로드 스킵")
                return nil
            }

            transaction.setData([
                "userId": userId,
                "nickname": nickname,
                "grade": grade.rawValue,
                "score": score,
                "gameGrade": gameGrade.rawValue,
                "correctCount": correctCount,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: docRef)
            return nil
        }) { _, error in
            if let error {
                print("❌ [RemoteLeaderboard] 업로드 실패: \(error.localizedDescription)")
            } else {
                print("✅ [RemoteLeaderboard] 점수 업로드 완료 — score: \(score)")
            }
        }
    }

    // MARK: - 삭제

    /// 내 공개 리더보드 기록을 지운다.
    ///
    /// 「데이터 초기화」가 로컬만 지우면 거짓이 된다. 별명과 점수는 글로벌
    /// 리더보드에 올라가 다른 사용자에게 계속 보이기 때문이다.
    ///
    /// 완료를 기다리지 않는다. Firestore 는 오프라인에서도 삭제를 로컬 큐에
    /// 영속으로 쌓아 두고 다음 연결에서 보내므로, 기다리지 않아도 유실되지
    /// 않는다. 반대로 기다리면 비행기 모드에서 초기화가 멈춘 것처럼 보인다.
    func deleteMyEntry() {
        guard let userId = UserIdentityRepository.shared.userId else {
            print("ℹ️ [RemoteLeaderboard] 로그인 전이라 지울 기록이 없다")
            return
        }
        db.collection(collection).document(userId).delete { error in
            if let error {
                print("❌ [RemoteLeaderboard] 기록 삭제 실패: \(error.localizedDescription)")
            } else {
                print("✅ [RemoteLeaderboard] 공개 리더보드 기록 삭제 완료")
            }
        }
    }

    // MARK: - 리더보드 조회

    /// 전체 또는 학년별 상위 50명 조회 (유저당 1개 문서)
    func fetchLeaderboard(grade: Grade? = nil) async throws -> [RemoteLeaderboardEntry] {
        var query: Query = db.collection(collection)
            .order(by: "score", descending: true)
            .limit(to: 50)

        if let grade {
            query = db.collection(collection)
                .whereField("grade", isEqualTo: grade.rawValue)
                .order(by: "score", descending: true)
                .limit(to: 50)
        }

        let snapshot = try await query.getDocuments()

        // userId 기준 중복 제거 — 이전 addDocument 방식으로 쌓인 레거시 데이터 방어
        var seen = Set<String>()
        let unique = snapshot.documents.filter { doc in
            let uid = doc.data()["userId"] as? String ?? doc.documentID
            return seen.insert(uid).inserted
        }

        return unique.enumerated().compactMap { index, doc in
            RemoteLeaderboardEntry(rank: index + 1, docId: doc.documentID, data: doc.data())
        }
    }

    /// 내 순위 조회 (내 최고 점수보다 높은 유저 수 + 1)
    func fetchMyRank(grade: Grade? = nil) async -> Int? {
        guard let userId = UserIdentityRepository.shared.userId else { return nil }
        let docRef = db.collection(collection).document(userId)

        do {
            let myDoc = try await docRef.getDocument()
            guard let myScore = myDoc.data()?["score"] as? Int else { return nil }

            var countQuery: Query = db.collection(collection)
                .whereField("score", isGreaterThan: myScore)

            if let grade {
                countQuery = db.collection(collection)
                    .whereField("grade", isEqualTo: grade.rawValue)
                    .whereField("score", isGreaterThan: myScore)
            }

            let countSnapshot = try await countQuery.getDocuments()
            return countSnapshot.documents.count + 1
        } catch {
            print("❌ [RemoteLeaderboard] 내 순위 조회 실패: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - 원격 리더보드 항목 모델

struct RemoteLeaderboardEntry: Identifiable {
    let id: String          // Firestore 문서 ID (= userId)
    let rank: Int
    let userId: String
    let nickname: String
    let grade: Grade
    let score: Int
    let gameGrade: GameGrade
    let correctCount: Int
    let date: Date

    var isMe: Bool {
        guard let myId = UserIdentityRepository.shared.userId else { return false }
        return userId == myId
    }

    init?(rank: Int, docId: String, data: [String: Any]) {
        guard
            let userId = data["userId"] as? String,
            let nickname = data["nickname"] as? String,
            let gradeRaw = data["grade"] as? Int,
            let grade = Grade(rawValue: gradeRaw),
            let score = data["score"] as? Int,
            let gameGradeRaw = data["gameGrade"] as? String,
            let gameGrade = GameGrade(rawValue: gameGradeRaw)
        else { return nil }

        self.id = docId
        self.rank = rank
        self.userId = userId
        self.nickname = nickname
        self.grade = grade
        self.score = score
        self.gameGrade = gameGrade
        self.correctCount = data["correctCount"] as? Int ?? 0
        self.date = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
