import SwiftUI
import Combine

// MARK: - 🏎️ SetTelemetry: 1セットごとの走行データ (将来の拡張性を担保)
struct SetTelemetry: Codable, Hashable {
    var weight: Double        // 必須：手動入力重量
    var reps: Int             // 必須：手動入力レップ数
    var targetReps: Int       // 必須：目標レップ数
    var velocity: Double? = nil // オプショナル：挙動速度 (m/s)
    var rpe: Int? = nil       // オプショナル：主観的疲労度
}

// MARK: - 📡 PitRadioEngine: レースエンジニア風判定ロジック
class PitRadioEngine: ObservableObject {
    static let shared = PitRadioEngine()
    private init() {}
    
    enum ActionState {
        case shiftUp   // 重量増加
        case shiftDown // 重量低下
        case stay      // 維持
        case push      // 目標まであと少し（追記ロジック）
    }
    
    struct Recommendation {
        let message: String
        let action: ActionState
        let color: Color
        let suggestedAdjustment: String
    }
    
    /// セットデータを受け取り、リコメンドを生成する
    func analyze(telemetry: SetTelemetry, exerciseName: String) -> Recommendation {
        let diff = telemetry.reps - telemetry.targetReps
        let part = MuscleDatabase.shared.getVectorPart(for: exerciseName)
        let muscleData = MuscleDatabase.shared.muscleInfo[part]
        
        // 1. シフトアップ（重量増加）: 目標+2回以上
        if diff >= 2 {
            var message = "エンジン出力、まだまだ余裕あり（Over-revving）。次セット、ギアを一つ上げろ（+2.5kg シフトアップ推奨）。"
            if let data = muscleData {
                message += "\n📡 追記: \(data.part.rawValue.uppercased()) は\(data.fiberType)で、\(data.optimalReps)での高強度刺激が肥大に有効だ。"
            }
            return Recommendation(
                message: message,
                action: .shiftUp,
                color: .green,
                suggestedAdjustment: "+2.5kg"
            )
        }
        
        // 2. シフトダウン（重量低下）: 目標-2回以下
        if diff <= -2 {
            var message = "オーバーヒートの兆候あり。無理するな、次セットは少しダウンフォースを削れ（-2.5kg シフトダウン推奨）。"
            if let _ = muscleData {
                message += "\n📡 追記: 無理な連続周回は避けろ。"
            }
            return Recommendation(
                message: message,
                action: .shiftDown,
                color: .red,
                suggestedAdjustment: "-2.5kg"
            )
        }
        
        // 3. ステイ（重量維持）: 目標と同じ または +1回
        if diff == 0 || diff == 1 {
            var message = "適正回転数をキープ（Optimal zone）。素晴らしいペースだ、次も同じセッティング（重量）で攻めろ。"
            if let data = muscleData {
                message += "\n📡 追記: \(data.advice)"
            }
            return Recommendation(
                message: message,
                action: .stay,
                color: .cyan,
                suggestedAdjustment: "KEEP"
            )
        }
        
        // 4. フォールバック（目標-1回など）: 粘りの走り
        return Recommendation(
            message: "限界付近のデッドヒートだ。集中を切らすな、次セットで目標レップを確実に仕留めろ。",
            action: .push,
            color: .orange,
            suggestedAdjustment: "STAY"
        )
    }
}
