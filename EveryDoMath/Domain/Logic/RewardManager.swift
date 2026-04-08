import Foundation

// 업적 및 스트릭 판정 로직
struct RewardManager {

    /// 게임 완료 후 새로 달성한 업적 목록을 반환
    static func checkNewAchievements(
        session: GameSession,
        profile: PlayerProfile,
        currentStreak: Int,
        existingAchievements: [Achievement]
    ) -> [Achievement] {
        let unlockedTypes = Set(existingAchievements.map { $0.type })
        var newAchievements: [Achievement] = []

        func tryUnlock(_ type: AchievementType) {
            guard !unlockedTypes.contains(type) else { return }
            newAchievements.append(Achievement(type: type))
        }

        // 첫 게임
        if profile.totalGamesPlayed == 0 {
            tryUnlock(.firstGame)
        }

        // 만점 (20문제 모두 정답)
        if session.correctCount == GameSession.problemCount {
            tryUnlock(.perfectScore)
        }

        // 스트릭 업적
        let streak = currentStreak
        if streak >= 3 { tryUnlock(.streak3) }
        if streak >= 7 { tryUnlock(.streak7) }
        if streak >= 30 { tryUnlock(.streak30) }

        // 스피드킹 (전체 풀이 시간 60초 이내)
        if session.timeTaken <= 60.0 && session.correctCount == GameSession.problemCount {
            tryUnlock(.speedDemon)
        }

        // S등급 달성
        if session.gameGrade == .S {
            tryUnlock(.gradeS)
        }

        // 플레이 횟수 업적 (현재 게임 포함)
        let totalPlayed = profile.totalGamesPlayed + 1
        if totalPlayed >= 10 { tryUnlock(.played10) }
        if totalPlayed >= 50 { tryUnlock(.played50) }
        if totalPlayed >= 100 { tryUnlock(.played100) }

        return newAchievements
    }

    /// 스트릭 계산: 오늘 날짜 기준으로 연속 기록 확인
    static func calculateStreak(dailyRecords: [DailyRecord]) -> Int {
        guard !dailyRecords.isEmpty else { return 0 }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // 날짜 기준 내림차순 정렬
        let sortedRecords = dailyRecords
            .compactMap { record -> (String, Date)? in
                guard let date = formatter.date(from: record.dateString) else { return nil }
                return (record.dateString, date)
            }
            .sorted { $0.1 > $1.1 }

        guard let latestDate = sortedRecords.first?.1 else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let latestDay = calendar.startOfDay(for: latestDate)

        // 오늘 또는 어제 플레이하지 않았으면 스트릭 0
        let daysDiff = calendar.dateComponents([.day], from: latestDay, to: today).day ?? 0
        if daysDiff > 1 { return 0 }

        // 연속 일수 계산
        var streak = 1
        var previousDate = latestDay

        for i in 1..<sortedRecords.count {
            let currentDate = calendar.startOfDay(for: sortedRecords[i].1)
            let diff = calendar.dateComponents([.day], from: currentDate, to: previousDate).day ?? 0

            if diff == 1 {
                streak += 1
                previousDate = currentDate
            } else if diff == 0 {
                // 같은 날 중복 기록
                continue
            } else {
                break
            }
        }

        return streak
    }
}
