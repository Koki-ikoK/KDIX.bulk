import Foundation
import Combine

// MARK: - 科学的筋肥大オートレギュレーション・エンジン (Dynamic Double Progression)
class AutoregulationEngine: ObservableObject {
    static let shared = AutoregulationEngine()
    private init() {}
    
    struct Recommendation {
        var nextWeight: Double
        var nextRepsTarget: String
        var reason: String
        var actionType: String
    }
    
    /// 次セットの推奨重量を計算する
    /// - Parameters:
    ///   - targetMin: 目標レップ数の下限 (例: 8)
    ///   - targetMax: 目標レップ数の上限 (例: 12)
    ///   - currentWeight: 今回扱った重量
    ///   - actualReps: 今回実際に挙上した回数
    ///   - rir: 余力 (Reps In Reserve)。デフォルト0(限界)。
    ///   - weightStep: 施設のプレートの最小単位 (例: 2.5kg)
    func recommendNextSet(targetMin: Int = 8, targetMax: Int = 12, currentWeight: Double, actualReps: Int, rir: Double = 0.0, weightStep: Double = 2.5) -> Recommendation {
        let fatigueRepDrop: Double = 1.5 // 1セットごとの疲労による平均低下レップ数
        
        // RIRを加味した推測限界レップ数
        let estimatedMaxReps = Double(actualReps) + rir
        
        var rec = Recommendation(
            nextWeight: currentWeight,
            nextRepsTarget: "\(targetMin) - \(targetMax)",
            reason: "",
            actionType: "MAINTAIN"
        )
        
        // 条件分岐1: レップ数が目標上限を上回った場合（重量不足による有効レップの損失）
        if estimatedMaxReps > Double(targetMax) {
            let overReps = estimatedMaxReps - Double(targetMax)
            let weightIncreaseFactor = 1.0 + (0.04 * overReps) // 4%ルール
            let rawNewWeight = currentWeight * weightIncreaseFactor
            
            rec.nextWeight = roundToStep(rawNewWeight, step: weightStep)
            rec.reason = "推測限界レップ(\(Int(estimatedMaxReps))回)が上限(\(targetMax)回)を超過しました。高閾値運動単位を動員し有効レップを最大化するため、重量を増加させます。"
            rec.actionType = "INCREASE"
            
        // 条件分岐2: レップ数が目標下限を下回った場合（重量過多によるボリューム不足）
        } else if estimatedMaxReps < Double(targetMin) {
            let underReps = Double(targetMin) - estimatedMaxReps
            let weightDecreaseFactor = 1.0 - (0.04 * underReps)
            let rawNewWeight = currentWeight * weightDecreaseFactor
            
            rec.nextWeight = roundToStep(rawNewWeight, step: weightStep)
            rec.reason = "推測限界レップ(\(Int(estimatedMaxReps))回)が下限(\(targetMin)回)に達していません。機械的張力の持続時間を確保するため、重量を減少させます。"
            rec.actionType = "DECREASE"
            
        // 条件分岐3: レップ数が適正な範囲内に収まった場合（スイートスポット）
        } else {
            let expectedRepsNextSet = estimatedMaxReps - fatigueRepDrop
            
            if expectedRepsNextSet < Double(targetMin) {
                // 疲労により次セットで目標下限を下回ることが確実な場合、バックオフセットを適用
                let rawNewWeight = currentWeight * 0.95 // 5%ドロップ
                rec.nextWeight = roundToStep(rawNewWeight, step: weightStep)
                rec.reason = "適正範囲内ですが、次セットの疲労を考慮し、有効レップを維持するため5%のバックオフ(重量ダウン)を適用します。"
                rec.actionType = "BACK-OFF"
            } else {
                rec.nextWeight = currentWeight
                rec.reason = "最適な強度です。疲労によるレップ低下を見込んでも目標範囲に収まるため、重量を維持して限界(RIR 0-1)まで追い込んでください。"
                rec.actionType = "MAINTAIN"
            }
        }
        
        if rec.nextWeight < weightStep {
            rec.nextWeight = weightStep
        }
        
        return rec
    }
    
    private func roundToStep(_ value: Double, step: Double) -> Double {
        return round(value / step) * step
    }
}
