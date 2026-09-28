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

                    // 알림 권한은 여기서 요청하지 않는다.
                    // 첫 실행에 무조건 권한 팝업을 띄우면, 아직 별명도 안 정한
                    // 아이에게 앱이 먼저 뭔가를 요구하는 장면이 된다.
                    // 권한은 부모가 목표 설정에서 학습 알림을 켤 때만 요청한다
                    // (GoalSettingsView).
                }
        }
    }
}
