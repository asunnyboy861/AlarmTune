import SwiftUI

@main
struct AlarmTuneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            AlarmListView()
                .tint(themeManager.accentColor)
        }
    }
}
