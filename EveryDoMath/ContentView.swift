import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        AppRootView(appState: appState)
    }
}

// @Bindable을 올바르게 사용하기 위해 별도 View로 분리
private struct AppRootView: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if appState.isFirstLaunch {
                ProfileSetupView()
                    .environment(appState)
            } else {
                NavigationStack(path: $appState.navigationPath) {
                    HomeView()
                        .navigationDestination(for: AppDestination.self) { dest in
                            switch dest {
                            case .game(let session):
                                GameView(session: session)
                            case .result(let session):
                                ResultView(session: session)
                            case .leaderboard:
                                LeaderboardView()
                            case .profile:
                                ProfileView()
                            case .profileSetup:
                                ProfileSetupView()
                            case .parentDashboard:
                                ParentDashboardView()
                            }
                        }
                }
                .environment(appState)
            }
        }
    }
}

#Preview {
    ContentView()
}
