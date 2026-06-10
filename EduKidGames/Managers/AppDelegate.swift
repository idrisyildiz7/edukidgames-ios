import Combine
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications
#if DEBUG
import DebugSwift
#endif

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    static weak var shared: AppDelegate?
    static var pendingDeepLinkRoute: String?

#if DEBUG
    private let debugSwift = DebugSwift()
#endif

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppDelegate.shared = self
        configureFirebaseIfNeeded()

        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, _ in
            #if DEBUG
            print("[Push] Bildirim izni verildi mi?: \(granted)")
            #endif
        }
        application.registerForRemoteNotifications()

#if DEBUG
        debugSwift.setup()
        debugSwift.show()
#endif
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

    // MARK: - Remote Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
        #if DEBUG
        print("[Push] APNs token alındı.")
        #endif
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("[Push] APNs register failed: \(error.localizedDescription)")
        #endif
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        #if DEBUG
        print("[Push] FCM token alındı.")
        #endif
        guard AuthSessionStore.allowsDeviceTokenRegistration,
              AuthSessionStore.isLoggedIn,
              let token = AuthSessionStore.accessToken,
              let userId = AuthSessionStore.userId else { return }
        Task {
            await Self.registerDeviceToken(accessToken: token, userId: userId, fcmToken: fcmToken)
        }
    }

    static func sendDeviceTokenToServerIfNeeded() {
        guard FirebaseApp.app() != nil,
              AuthSessionStore.allowsDeviceTokenRegistration,
              AuthSessionStore.isLoggedIn else { return }
        Messaging.messaging().token { fcmToken, error in
            if let error {
                #if DEBUG
                print("[Push] FCM token alınamadı: \(error.localizedDescription)")
                #endif
                return
            }
            guard let fcmToken,
                  let token = AuthSessionStore.accessToken,
                  let userId = AuthSessionStore.userId else { return }
            Task {
                await Self.registerDeviceToken(accessToken: token, userId: userId, fcmToken: fcmToken)
            }
        }
    }

    private static func registerDeviceToken(accessToken: String, userId: String, fcmToken: String) async {
        let success = await AuthService.registerDeviceToken(
            accessToken: accessToken,
            userId: userId,
            fcmToken: fcmToken
        )
        #if DEBUG
        if success {
            print("[Push] Token başarıyla server'a kaydedildi.")
        } else {
            print("[Push] Token gönderilirken hata oluştu.")
        }
        #endif
    }

    // MARK: - UNUserNotificationCenterDelegate

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
