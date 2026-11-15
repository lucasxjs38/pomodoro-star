import SwiftUI

@main
struct PomodoroStarApp: App {
    var body: some Scene {
        WindowGroup("番茄小星球") {
            RootView()
                .frame(minWidth: 420, minHeight: 560)
        }
    }
}
