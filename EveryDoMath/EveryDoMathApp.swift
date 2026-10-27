import SwiftUI
import FirebaseAnalytics
import FirebaseCore

@main
struct EveryDoMathApp: App {
    init() {
        FirebaseApp.configure()

        // GoogleService-Info.plist 가 IS_ANALYTICS_ENABLED = false 로 내려온다.
        // Firebase 콘솔에는 GA 속성(everydomath)과 데이터 스트림(매일수학)이
        // 정상 연결돼 있는데도 설정 파일만 비활성으로 발급된다 — 파일을 두 번
        // 다시 받아도 같았다. 그래서 앱에서 명시적으로 켠다.
        //
        // INFOPLIST_KEY_FIREBASE_ANALYTICS_COLLECTION_ENABLED 로도 시도했지만
        // 그 접두사는 Apple 이 정의한 키에만 동작해서 빌드 결과물에 들어가지 않았다.
        //
        // 광고 식별자(IDFA)는 수집하지 않는다 —
        // FirebaseAnalyticsIdentitySupport 를 링크하지 않았다.
        Analytics.setAnalyticsCollectionEnabled(true)
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
