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
                    // Firestore 접근 전에 신원을 먼저 확보한다.
                    await UserIdentityRepository.shared.signInIfNeeded()
                    _ = await NotificationManager.shared.requestPermission()
                }
        }
    }
}
