import Foundation

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
        case .firstGame:    return L("achievement.firstGame.title")
        case .perfectScore: return L("achievement.perfectScore.title")
        case .streak3:      return L("achievement.streak3.title")
        case .streak7:      return L("achievement.streak7.title")
        case .streak30:     return L("achievement.streak30.title")
        case .speedDemon:   return L("achievement.speedDemon.title")
        case .gradeS:       return L("achievement.gradeS.title")
        case .played10:     return L("achievement.played10.title")
        case .played50:     return L("achievement.played50.title")
        case .played100:    return L("achievement.played100.title")
        }
    }

    var description: String {
        switch self {
        case .firstGame:    return L("achievement.firstGame.desc")
        case .perfectScore: return L("achievement.perfectScore.desc")
        case .streak3:      return L("achievement.streak3.desc")
        case .streak7:      return L("achievement.streak7.desc")
        case .streak30:     return L("achievement.streak30.desc")
        case .speedDemon:   return L("achievement.speedDemon.desc")
        case .gradeS:       return L("achievement.gradeS.desc")
        case .played10:     return L("achievement.played10.desc")
        case .played50:     return L("achievement.played50.desc")
        case .played100:    return L("achievement.played100.desc")
        }
    }

    var iconName: String {
        switch self {
        case .firstGame:    return "star.fill"
        case .perfectScore: return "crown.fill"
        case .streak3:      return "flame.fill"
        case .streak7:      return "flame.fill"
        case .streak30:     return "trophy.fill"
        case .speedDemon:   return "bolt.fill"
        case .gradeS:       return "star.circle.fill"
        case .played10:     return "10.circle.fill"
        case .played50:     return "50.circle.fill"
        case .played100:    return "100.circle.fill"
        }
    }
}
