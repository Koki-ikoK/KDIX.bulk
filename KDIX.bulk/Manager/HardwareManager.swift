import SwiftUI
import AVFoundation

// MARK: - 📳 不死身のハードウェアマネージャー（完全ゾンビ対策版）
class HardwareManager {
    static let shared = HardwareManager()
    
    // アプリ起動中ずっと生き続けるため、絶対にゾンビ化しない
    private var selectionGen: UISelectionFeedbackGenerator?
    private var heavyGen: UIImpactFeedbackGenerator?
    private var mediumGen: UIImpactFeedbackGenerator?
    private var rigidGen: UIImpactFeedbackGenerator?
    
    private init() {
        // メインスレッドで安全に初期化
        DispatchQueue.main.async {
            self.selectionGen = UISelectionFeedbackGenerator()
            self.heavyGen = UIImpactFeedbackGenerator(style: .heavy)
            self.mediumGen = UIImpactFeedbackGenerator(style: .medium)
            self.rigidGen = UIImpactFeedbackGenerator(style: .rigid)
            
            self.selectionGen?.prepare()
            self.heavyGen?.prepare()
            self.mediumGen?.prepare()
            self.rigidGen?.prepare()
        }
    }
    
    // 💥 画面の処理（ジェスチャー）を邪魔しないよう、非同期で安全に鳴らす！
    func playSelection() {
        DispatchQueue.main.async {
            self.selectionGen?.selectionChanged()
            self.selectionGen?.prepare()
        }
    }
    
    func playHeavy() {
        DispatchQueue.main.async {
            self.heavyGen?.impactOccurred(intensity: 1.0)
            self.heavyGen?.prepare()
        }
    }
    
    func playMedium() {
        DispatchQueue.main.async {
            self.mediumGen?.impactOccurred()
            self.mediumGen?.prepare()
        }
    }
    
    func playRigid() {
        DispatchQueue.main.async {
            self.rigidGen?.impactOccurred()
            self.rigidGen?.prepare()
        }
    }
}
