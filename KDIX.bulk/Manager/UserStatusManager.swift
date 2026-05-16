
import SwiftUI
import Combine

// MARK: - 📊 ステータスの定義
enum WorkoutStatus: String, Codable {
    case idle = "未実施"
    case training = "トレーニング中"
    case finished = "完了"
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .training: return .green
        case .finished: return .blue
        }
    }
}

// MARK: - 🚀 ステータス・マネージャー
class UserStatusManager: ObservableObject {
    static let shared = UserStatusManager()
    
    @Published var currentStatus: WorkoutStatus = .idle
    
    // トレーニング開始
    func startTraining() {
        withAnimation {
            currentStatus = .training
        }
    }
    
    // トレーニング完了
    func finishTraining() {
        withAnimation {
            currentStatus = .finished
        }
    }
    
    // 翌日などのリセット用
    func resetStatus() {
        currentStatus = .idle
    }
}
