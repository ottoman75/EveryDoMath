import SwiftUI
import FirebaseCore

@main
struct EveryDoMathApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    // 스크린샷 촬영용 표본 데이터. 시뮬레이터 DEBUG 빌드에서
                    // 실행 인자가 있을 때만 동작한다.
                    UITestSeed.seedIfRequested()
                    // Firestore 접근 전에 신원을 먼저 확보한다.
                    await UserIdentityRepository.shared.signInIfNeeded()
                    _ = await NotificationManager.shared.requestPermission()
                }
        }
    }
}
