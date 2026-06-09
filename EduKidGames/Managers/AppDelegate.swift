import Combine
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    static weak var shared: AppDelegate?
    static var pendingDeepLinkRoute: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppDelegate.shared = self
        configureFirebaseIfNeeded()

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()
        return true
    }

    private func configureFirebaseIfNeeded() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let appId = plist["GOOGLE_APP_ID"] as? String,
              !appId.isEmpty,
              !appId.contains("placeholder") else {
            return
        }
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, AuthSessionStore.isLoggedIn,
              let token = AuthSessionStore.accessToken,
              let userId = AuthSessionStore.userId else { return }
        Task {
            await AuthService.registerDeviceToken(accessToken: token, userId: userId, fcmToken: fcmToken)
        }
    }

    static func sendDeviceTokenToServerIfNeeded() {
        guard FirebaseApp.app() != nil, AuthSessionStore.isLoggedIn else { return }
        Messaging.messaging().token { fcmToken, _ in
            guard let fcmToken,
                  let token = AuthSessionStore.accessToken,
                  let userId = AuthSessionStore.userId else { return }
            Task { await AuthService.registerDeviceToken(accessToken: token, userId: userId, fcmToken: fcmToken) }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let route = response.notification.request.content.userInfo["route"] as? String
        AppDelegate.pendingDeepLinkRoute = route
        NotificationCenter.default.post(name: .edukidPushDeepLink, object: route)
        completionHandler()
    }
}

extension Notification.Name {
    static let edukidPushDeepLink = Notification.Name("edukid.push.deeplink")
}
