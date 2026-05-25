import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // 1. ユーザーに通知の許可を求める
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                print("通知の許可エラー: \(error.localizedDescription)")
            } else if success {
                print("通知が許可されました！")
                self.scheduleNotifications()
            } else {
                print("通知が拒否されました")
            }
        }
    }
    
    // 2. フォアグラウンドでも通知を表示するためのデリゲートメソッド
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // フォアグラウンドでもバナー、音、バッジを許可する
        completionHandler([.banner, .sound, .badge])
    }
    
    // 3. 火・木・金の通知をセットする
    func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let scheduleDays = [
            (weekday: 3, title: "Day 1 起動推奨", body: "今日は火曜日。胸・肩前部・三頭を追い込む日です🔥"),
            (weekday: 5, title: "Day 2 起動推奨", body: "今日は木曜日。背中・二頭をバチバチにする日です🔥"),
            (weekday: 6, title: "Day 3 起動推奨", body: "今日は金曜日。脚と肩の日！週末前にやり切りましょう🔥")
        ]
        
        for schedule in scheduleDays {
            let content = UNMutableNotificationContent()
            content.title = schedule.title
            content.body = schedule.body
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.weekday = schedule.weekday
            dateComponents.hour = 18
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "WorkoutNotification_\(schedule.weekday)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // 💥 追加：ニトロ受信時の即時通知
    func showNitroAlert(from sender: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚡️ NITRO RECEIVED!"
        content.body = "\(sender) からニトロを受け取りました！"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "shift_up.mp3"))
        
        let request = UNNotificationRequest(
            identifier: "Nitro_\(UUID().uuidString)",
            content: content,
            trigger: nil // 即時
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 通知の送信失敗: \(error)")
            }
        }
    }
}
