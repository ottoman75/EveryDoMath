import SwiftUI

// 앱 전역 상태 및 의존성 컨테이너
@Observable
final class AppState {
    var navigationPath = NavigationPath()

    let gameRepo = GameRepository()
    let profileRepo = ProfileRepository()

    var profile: PlayerProfile?

    init() {
        // 앱 시작 시 즉시 로드해서 첫 렌더링부터 올바른 화면이 표시되도록
        profile = profileRepo.loadProfile()
    }

    func loadAppData() {
        profile = profileRepo.loadProfile()
    }

    var isFirstLaunch: Bool { profile == nil }
}

// 네비게이션 목적지
enum AppDestination: Hashable {
    case game(GameSession)
    case result(GameSession)
    case leaderboard
    case profile
    case profileSetup
    case parentDashboard
}
