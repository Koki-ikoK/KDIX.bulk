import Foundation
import SwiftUI
import Combine

class WorkoutSessionManager: ObservableObject {
    static let shared = WorkoutSessionManager()
    
    @Published var activeRoutine: WorkoutRoutine? = nil
    @Published var sessionStartTime: Date = Date()
    @Published var initialSecondsElapsed: Int = 0
    @Published var completedSets: [String: [Int: SetRecord]] = [:]
    @Published var activeExercises: [RoutineExercise] = []
    
    private init() {}
    
    func startSession(with routine: WorkoutRoutine) {
        if activeRoutine?.id == routine.id { return }
        
        self.activeRoutine = routine
        self.sessionStartTime = Date()
        self.initialSecondsElapsed = 0
        self.completedSets = [:]
        self.activeExercises = routine.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        
        // 既存の下書きがあればロード
        loadDraft(for: routine)
    }
    
    func endSession() {
        if let routine = activeRoutine {
            UserDefaults.standard.removeObject(forKey: "draft_\(routine.id.uuidString)")
            UserDefaults.standard.removeObject(forKey: "activeWorkoutId")
            
            let driverName = UserDefaults.standard.string(forKey: "driverName") ?? "GUEST"
            FirebaseManager.shared.clearLiveTelemetry(ownerName: driverName)
        }
        self.activeRoutine = nil
        self.completedSets = [:]
        self.activeExercises = []
    }
    
    func saveSet(exName: String, setNum: Int, weight: Double, reps: Int) {
        if completedSets[exName] == nil { completedSets[exName] = [:] }
        completedSets[exName]?[setNum] = SetRecord(weight: weight, reps: reps)
        saveDraft()
    }
    
    func saveDraft() {
        guard let routine = activeRoutine else { return }
        let totalSecs = initialSecondsElapsed + Int(Date().timeIntervalSince(sessionStartTime))
        let draft = WorkoutDraft(secondsElapsed: totalSecs, completedSets: completedSets, lastSavedDate: Date())
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: "draft_\(routine.id.uuidString)")
            UserDefaults.standard.set(routine.id.uuidString, forKey: "activeWorkoutId")
        }
    }
    
    private func loadDraft(for routine: WorkoutRoutine) {
        if let data = UserDefaults.standard.data(forKey: "draft_\(routine.id.uuidString)"),
           let draft = try? JSONDecoder().decode(WorkoutDraft.self, from: data) {
            self.completedSets = draft.completedSets
            let timeAway = Date().timeIntervalSince(draft.lastSavedDate)
            if timeAway < 43200 { // 12時間以内なら継続
                self.initialSecondsElapsed = draft.secondsElapsed + Int(timeAway)
            } else {
                self.initialSecondsElapsed = draft.secondsElapsed
            }
        }
    }
    
    func calculateTotalVolume() -> Double {
        var total: Double = 0
        for ex in activeExercises {
            if let sets = completedSets[ex.name] {
                // 💥 変更：ex.sets に縛られず、登録されている全セットを合計する
                for (_, record) in sets {
                    total += record.weight * Double(record.reps)
                }
            }
        }
        return total
    }
    
    func moveExercise(from: Int, to: Int) {
        guard activeExercises.indices.contains(from), activeExercises.indices.contains(to) else { return }
        let element = activeExercises.remove(at: from)
        activeExercises.insert(element, at: to)
        // orderIndexを更新して永続化を確実にする
        for i in 0..<activeExercises.count {
            activeExercises[i].orderIndex = i
        }
        saveDraft()
    }
}
