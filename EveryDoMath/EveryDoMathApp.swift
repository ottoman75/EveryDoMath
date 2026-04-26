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
                    _ = await NotificationManager.shared.requestPermission()
                }
        }
    }
}
