import AVFoundation
import AudioToolbox
import SwiftUI

// MARK: - 🔊 ワイスピ仕様：リアル・シフトサウンドマネージャー (メモリ固定・完全防衛版)
class ShiftSoundManager {
    static let shared = ShiftSoundManager()
    
    // 💥 解決策：全てのプレイヤーをこの辞書に叩き込み、メモリから消えるのを物理的に防ぐ
    private var allPlayers: [String: AVAudioPlayer] = [:]
    private var extraRevPlayer: AVAudioPlayer? // 💥 追加：音量2倍用（オーバーレイ）
    
    private init() {
        self.loadAllSounds()
    }
    
    private func loadAllSounds() {
        let soundFiles = ["shift_up", "shift_down", "rev_match", "engine_base"]
        
        for file in soundFiles {
            if let url = Bundle.main.url(forResource: file, withExtension: "mp3") ?? Bundle.main.url(forResource: file, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    if file == "engine_base" { player.enableRate = true }
                    
                    self.allPlayers[file] = player
                    
                    // 💥 改善：音量を1.0の「2倍」にするため、もう一つ全く同じプレイヤーを作って重ねる
                    if file == "rev_match" {
                        extraRevPlayer = try AVAudioPlayer(contentsOf: url)
                        extraRevPlayer?.prepareToPlay()
                    }
                    
                    print("🔊 Loaded: \(file)")
                } catch {
                    print("⚠️ Load failed: \(file)")
                }
            }
        }
        
        // オーディオセッションの設定
        // 💥 修正：.playback + .mixWithOthers に統一し、他アプリの音を止めないようにする
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - シフト操作開始（ストゥトゥトゥ！）
    func playShiftDragStart() {
        if AppSettings.shared.isShiftSoundEnabled {
            if let revPlayer = allPlayers["rev_match"] {
                revPlayer.currentTime = 0
                revPlayer.volume = 1.0
                revPlayer.play()
                
                // 💥 音量を倍増させる魔法
                extraRevPlayer?.currentTime = 0
                extraRevPlayer?.volume = 1.0
                extraRevPlayer?.play()
            }
        }
    }
    
    // MARK: - シフトアップ完了（ガコンッ → ブォォン！）
    func playShiftUpSequence(gear: Int) {
        // 💥 シフト音の設定をチェック
        if AppSettings.shared.isShiftSoundEnabled {
            if let shiftPlayer = allPlayers["shift_up"] {
                shiftPlayer.currentTime = 0
                shiftPlayer.volume = 1.0
                shiftPlayer.play()
            }
        }
        
        // 💥 エンジン音の設定をチェック
        if AppSettings.shared.isEngineSoundEnabled {
            if let enginePlayer = allPlayers["engine_base"] {
                let targetRate = 1.0 + (Float(gear) * 0.15) // N(0) -> 1速の時に gear=1 なので 1.15 になる
                
                // 💥 改善：shift_upの音（ガコンッ）が終わった直後にエンジンを鳴らす
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    enginePlayer.stop()
                    // engine_base.mp3 は頭が静かなので、0.5秒付近から再生して確実にブォォンと鳴らす
                    enginePlayer.currentTime = 0.5 
                    enginePlayer.volume = 1.0 // 確実に音量をMAXに
                    enginePlayer.rate = min(targetRate, 2.0)
                    enginePlayer.play()
                }
            }
        }
    }
    
    // MARK: - シフトダウン（減速 ＆ ストゥトゥトゥ！）
    func playShiftDownSequence(gear: Int) {
        // 💥 シフト音・ターボ音の設定をチェック
        if AppSettings.shared.isShiftSoundEnabled {
            if let downPlayer = allPlayers["shift_down"],
               let revPlayer = allPlayers["rev_match"] {
                downPlayer.currentTime = 0
                downPlayer.volume = 1.0
                downPlayer.play()
                
                revPlayer.currentTime = 0
                revPlayer.volume = 1.0
                revPlayer.play()
                
                extraRevPlayer?.currentTime = 0
                extraRevPlayer?.volume = 1.0
                extraRevPlayer?.play()
            }
        }
        
        // 💥 エンジン音の設定をチェック
        if AppSettings.shared.isEngineSoundEnabled {
            if let enginePlayer = allPlayers["engine_base"] {
                let targetRate = 1.0 + (Float(gear) * 0.15)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    enginePlayer.stop()
                    enginePlayer.currentTime = 0.5
                    enginePlayer.volume = 1.0
                    enginePlayer.rate = min(targetRate + 0.3, 2.0)
                    enginePlayer.play()
                }
            }
        }
    }
}
