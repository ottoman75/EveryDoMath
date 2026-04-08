import Foundation

// 업적 구조체
struct Achievement: Codable, Identifiable {
    let id: UUID
    let type: AchievementType
    let unlockedAt: Date

    init(type: AchievementType) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = Date()
    }
}

// 업적 타입 열거형
enum AchievementType: String, Codable, CaseIterable {
    case firstGame
    case perfectScore
    case streak3
    case streak7
    case streak30
    case speedDemon
    case gradeS
    case played10
    case played50
    case played100

    var title: String {
        switch self {
        case .firstGame: return "첫 게임"
        case .perfectScore: return "만점!"
        case .streak3: return "3일 연속"
        case .streak7: return "7일 마스터"
        case .streak30: return "30일 레전드"
        case .speedDemon: return "스피드킹"
        case .gradeS: return "S등급 달성"
        case .played10: return "10회 달성"
        case .played50: return "50회 달성"
        case .played100: return "100회 달성"
        }
    }

    var description: String {
        switch self {
        case .firstGame: return "첫 번째 게임을 완료했습니다"
        case .perfectScore: return "20문제를 모두 맞혔습니다"
        case .streak3: return "3일 연속으로 플레이했습니다"
        case .streak7: return "7일 연속으로 플레이했습니다"
        case .streak30: return "30일 연속으로 플레이했습니다"
        case .speedDemon: return "전체 풀이 시간이 60초 이내입니다"
        case .gradeS: return "S등급을 달성했습니다"
        case .played10: return "누적 10회 플레이했습니다"
        case .played50: return "누적 50회 플레이했습니다"
        case .played100: return "누적 100회 플레이했습니다"
        }
    }

    var iconName: String {
        switch self {
        case .firstGame: return "star.fill"
        case .perfectScore: return "crown.fill"
        case .streak3: return "flame.fill"
        case .streak7: return "flame.fill"
        case .streak30: return "trophy.fill"
        case .speedDemon: return "bolt.fill"
        case .gradeS: return "star.circle.fill"
        case .played10: return "10.circle.fill"
        case .played50: return "50.circle.fill"
        case .played100: return "100.circle.fill"
        }
    }
}
