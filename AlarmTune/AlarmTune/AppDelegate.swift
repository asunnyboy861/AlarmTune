import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AlarmScheduler.shared.registerNotificationCategories()
        AlarmScheduler.shared.requestAuthorization { granted in
            if !granted {
                print("Notification permission not granted")
            }
        }
        return true
    }
}
