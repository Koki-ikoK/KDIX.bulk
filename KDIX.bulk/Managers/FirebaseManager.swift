import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Combine

// 💥 構造体：リアルタイムテレメトリ
struct LiveTelemetry: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerName: String
    var currentRoutineTitle: String
    var currentExercise: String
    var currentSet: Int
    var lastUpdated: Date
    var nitroCount: Int = 0 
}

struct LeaderboardEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerName: String
    var totalVolume: Int
    var date: Date
}

// 💥 構造体：コミュニティフィード用の投稿データ (強化版)
struct SharedMissionReport: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerName: String
    var routineName: String
    var routineID: String? 
    var totalVolume: Int
    var totalTime: String
    var themeColor: String
    var date: Date
    var hasPhoto: Bool
    var photoBase64: String? 
    var styleName: String? 
    var isRoutinePublic: Bool? // 💥 追加：インポート可能かどうかの判定用
}

// 互換性データ
struct CloudWorkoutLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerName: String
    var dayTitle: String
    var totalSeconds: Int
    var themeColor: String
    var date: Date
    var exercises: [CloudExerciseLog]
    var nitroCount: Int = 0
}

struct CloudExerciseLog: Codable {
    var name: String
    var sets: [CloudSetRecord]
}

struct CloudSetRecord: Codable {
    var setNumber: Int
    var weight: Double
    var reps: Int
}

struct CloudWorkoutRoutine: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerName: String
    var title: String
    var themeColor: String
    var exercises: [CloudRoutineExercise]
}

struct CloudRoutineExercise: Codable {
    var name: String
    var target: String
    var equipment: String
    var baseWeight: Double
    var baseReps: Int
    var sets: Int
    var orderIndex: Int
}

struct Driver: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var registeredAt: Date
}

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var communityLogs: [CloudWorkoutLog] = []
    @Published var liveTelemetries: [LiveTelemetry] = []
    @Published var driverRoutines: [CloudWorkoutRoutine] = []
    @Published var allDrivers: [Driver] = [] 
    @Published var sharedReports: [SharedMissionReport] = [] 
    
    private var listenerRegistration: ListenerRegistration?
    private var telemetryListenerRegistration: ListenerRegistration?
    private var nitroListenerRegistration: ListenerRegistration?
    private var driverListenerRegistration: ListenerRegistration? 
    private var sharedReportsListenerRegistration: ListenerRegistration? 
    
    private init() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("❌ 匿名ログイン失敗: \(error.localizedDescription)")
            } else {
                print("👤 匿名ログイン成功: \(authResult?.user.uid ?? "")")
            }
        }
    }
    
    // MARK: - 1. データの送信
    func uploadMissionReport(report: SharedMissionReport) {
        do {
            try db.collection("community_feed_v2").addDocument(from: report)
            print("🚀 コミュニティフィードへ投稿完了")
        } catch {
            print("❌ フィード投稿失敗: \(error)")
        }
    }

    func registerDriver(name: String) {
        let driver = Driver(name: name, registeredAt: Date())
        try? db.collection("drivers_v1").document(name).setData(from: driver)
    }

    func uploadWorkoutLog(_ log: WorkoutLog) {
        let entry = LeaderboardEntry(
            ownerName: log.ownerName,
            totalVolume: Int(log.totalVolume),
            date: log.date
        )
        try? db.collection("leaderboard_v3").addDocument(from: entry)
    }
    
    func uploadWorkoutRoutine(_ routine: WorkoutRoutine) {
        let cloudExercises = routine.exercises.map { ex in
            CloudRoutineExercise(
                name: ex.name, target: ex.target, equipment: ex.equipment,
                baseWeight: ex.baseWeight, baseReps: ex.baseReps, sets: ex.sets, orderIndex: ex.orderIndex
            )
        }
        let cloudRoutine = CloudWorkoutRoutine(
            ownerName: routine.ownerName, title: routine.title, themeColor: routine.themeColor, exercises: cloudExercises
        )
        try? db.collection("public_routines").document(routine.id.uuidString).setData(from: cloudRoutine)
    }
    
    func deleteWorkoutRoutine(_ routine: WorkoutRoutine) {
        db.collection("public_routines").document(routine.id.uuidString).delete() { error in
            if let error = error {
                print("❌ Firebaseルーティン削除失敗: \(error)")
            } else {
                print("🗑️ Firebaseからルーティンを削除しました")
            }
        }
    }
    
    // 💥 修正：欠落していたメソッドを復活
    func fetchPublicRoutines(for driverName: String) {
        db.collection("public_routines")
            .whereField("ownerName", isEqualTo: driverName)
            .getDocuments { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self?.driverRoutines = documents.compactMap { try? $0.data(as: CloudWorkoutRoutine.self) }
            }
    }
    
    private func stopListeningToTelemetry() {
        telemetryListenerRegistration?.remove()
    }
    
    // 💥 追加：ルーティンをIDで取得する
    func fetchRoutine(id: String, completion: @escaping (CloudWorkoutRoutine?) -> Void) {
        db.collection("public_routines").document(id).getDocument { snapshot, error in
            guard let document = snapshot, document.exists,
                  let routine = try? document.data(as: CloudWorkoutRoutine.self) else {
                completion(nil)
                return
            }
            completion(routine)
        }
    }

    // MARK: - 2. データの受信
    func startListeningToFeed() {
        listenerRegistration?.remove()
        listenerRegistration = db.collection("leaderboard_v3")
            .order(by: "date", descending: true).limit(to: 50)
            .addSnapshotListener { [weak self] querySnapshot, _ in
                guard let documents = querySnapshot?.documents else { return }
                self?.leaderboardEntries = documents.compactMap { try? $0.data(as: LeaderboardEntry.self) }
            }
        startListeningToTelemetry()
        startListeningToDrivers() 
        startListeningToSharedReports()
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        driverListenerRegistration?.remove() 
        sharedReportsListenerRegistration?.remove()
        stopListeningToTelemetry()
    }
    
    private func startListeningToDrivers() {
        driverListenerRegistration?.remove()
        driverListenerRegistration = db.collection("drivers_v1").limit(to: 200)
            .addSnapshotListener { [weak self] querySnapshot, _ in
                guard let documents = querySnapshot?.documents else { return }
                self?.allDrivers = documents.compactMap { try? $0.data(as: Driver.self) }
            }
    }

    private func startListeningToSharedReports() {
        sharedReportsListenerRegistration?.remove()
        sharedReportsListenerRegistration = db.collection("community_feed_v2")
            .order(by: "date", descending: true).limit(to: 30)
            .addSnapshotListener { [weak self] querySnapshot, _ in
                guard let documents = querySnapshot?.documents else { return }
                self?.sharedReports = documents.compactMap { try? $0.data(as: SharedMissionReport.self) }
            }
    }
    
    // MARK: - 3. ニトロ
    func sendNitroToLiveUser(ownerName: String, senderName: String) {
        let docRef = db.collection("live_telemetry").document(ownerName)
        docRef.updateData(["nitroCount": FieldValue.increment(Int64(1))]) { [weak self] error in
            if error == nil { self?.sendNitroNotification(to: ownerName, from: senderName) }
        }
    }
    
    private func sendNitroNotification(to receiver: String, from sender: String) {
        let notificationData: [String: Any] = ["receiverName": receiver, "senderName": sender, "timestamp": FieldValue.serverTimestamp()]
        db.collection("nitro_notifications").addDocument(data: notificationData)
    }

    func startListeningToNitroNotifications(for driverName: String) {
        if nitroListenerRegistration != nil { return } 
        nitroListenerRegistration = db.collection("nitro_notifications")
            .whereField("receiverName", isEqualTo: driverName)
            .addSnapshotListener { querySnapshot, _ in
                guard let changes = querySnapshot?.documentChanges else { return }
                for change in changes where change.type == .added {
                    if let data = change.document.data() as? [String: Any],
                       let sender = data["senderName"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp {
                        if abs(Date().timeIntervalSince(timestamp.dateValue())) < 5 {
                            NotificationManager.shared.showNitroAlert(from: sender)
                        }
                    }
                }
            }
    }
    
    // MARK: - 4. リアルタイム・テレメトリ
    func updateLiveTelemetry(ownerName: String, routineTitle: String, exercise: String, set: Int) {
        let telemetry = LiveTelemetry(ownerName: ownerName, currentRoutineTitle: routineTitle, currentExercise: exercise, currentSet: set, lastUpdated: Date())
        try? db.collection("live_telemetry").document(ownerName).setData(from: telemetry)
    }
    
    func clearLiveTelemetry(ownerName: String) {
        db.collection("live_telemetry").document(ownerName).delete()
    }
    
    private func startListeningToTelemetry() {
        telemetryListenerRegistration?.remove()
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        telemetryListenerRegistration = db.collection("live_telemetry")
            .whereField("lastUpdated", isGreaterThan: oneHourAgo)
            .addSnapshotListener { [weak self] querySnapshot, _ in
                guard let documents = querySnapshot?.documents else { return }
                self?.liveTelemetries = documents.compactMap { try? $0.data(as: LiveTelemetry.self) }
            }
    }
}
