import UIKit
import UserNotifications
import SwiftData

final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = AppNotificationDelegate()

    func requestAuthorisation() async {
        let centre = UNUserNotificationCenter.current()
        _ = try? await centre.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
        centre.delegate = self
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notification banners even when the app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle tap — route to the correct journey card
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        let info = response.notification.request.content.userInfo
        guard let idString = info["journeyID"] as? String,
              let id = UUID(uuidString: idString) else { return }
        NotificationCenter.default.post(name: .openJourney, object: id)
    }
}
