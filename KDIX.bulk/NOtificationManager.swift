import UserNotifications

class NotificationManager {
    static let shared = NotificationManager() // シングルトン（どこからでも呼べるようにする）
    
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
    
    // 2. 火・木・金の通知をセットする
    func scheduleNotifications() {
        // 古い通知設定が重複しないように一度クリア
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 日: 1, 月: 2, 火: 3, 水: 4, 木: 5, 金: 6, 土: 7
        // 火(3), 木(5), 金(6) に設定
        let scheduleDays = [
            (weekday: 3, title: "Day 1 起動推奨", body: "今日は火曜日。胸・肩前部・三頭を追い込む日です🔥"),
            (weekday: 5, title: "Day 2 起動推奨", body: "今日は木曜日。背中・二頭をバチバチにする日です🔥"),
            (weekday: 6, title: "Day 3 起動推奨", body: "今日は金曜日。脚と肩の日！週末前にやり切りましょう🔥")
        ]
        
        for schedule in scheduleDays {
            let content = UNMutableNotificationContent()
            content.title = schedule.title
            content.body = schedule.body
            content.sound = .default // デフォルトの通知音
            
            // 毎週指定曜日の「夕方18時00分」に通知する設定
            var dateComponents = DateComponents()
            dateComponents.weekday = schedule.weekday
            dateComponents.hour = 18   // 好きな時間に変更してください（例: 18時）
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "WorkoutNotification_\(schedule.weekday)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("通知のスケジュール設定に失敗しました: \(error.localizedDescription)")
                }
            }
        }
    }
}
