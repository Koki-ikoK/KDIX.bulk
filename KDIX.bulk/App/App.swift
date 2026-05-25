
import SwiftUI
import SwiftData
import FirebaseCore // 💥 追加：Firebaseのコアモジュール

// 💥 追加：Firebaseの初期化を行うためのAppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase Configured Successfully!")
        
        // 💥 改善：通知デリゲートを明示的にセット
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        NotificationManager.shared.requestAuthorization()
        
        // 💥 追加：ドライバー名が登録済みならニトロ通知の監視を開始
        if let driverName = UserDefaults.standard.string(forKey: "driverName") {
            FirebaseManager.shared.startListeningToNitroNotifications(for: driverName)
        }
        
        return true
    }
}

@main  // 👈 この一行が超重要！これが「玄関口」の印です
struct KDIX_bulkApp: App {
    // 💥 追加：AppDelegateをSwiftUIアプリに接続する
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView() // 👈 最初に表示する画面
        }
        .modelContainer(for: [WorkoutLog.self, WorkoutRoutine.self, CustomExercise.self])
    }
}
