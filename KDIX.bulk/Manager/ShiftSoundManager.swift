import AVFoundation
import AudioToolbox
import SwiftUI

// MARK: - 🔊 ワイスピ仕様：リアル・シフトサウンドマネージャー (メモリ固定・完全防衛版)
class ShiftSoundManager {
    static let shared = ShiftSoundManager()
    
    // 💥 解決策：全てのプレイヤーをこの辞書に叩き込み、メモリから消えるのを物理的に防ぐ
    private var allPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        // メインスレッドのフリーズを防ぐ
        DispatchQueue.global(qos: .userInteractive).async {
            self.loadAllSounds()
        }
    }
    
    private func loadAllSounds() {
        let soundFiles = ["shift_up", "shift_down", "rev_match", "engine_base"]
        
        for file in soundFiles {
            if let url = Bundle.main.url(forResource: file, withExtension: "mp3") ?? Bundle.main.url(forResource: file, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    if file == "engine_base" { player.enableRate = true }
                    
                    // 💥 ここで辞書に保存！これで「deallocated」されることは100%ありません
                    self.allPlayers[file] = player
                    print("🔊 Loaded: \(file)")
                } catch {
                    print("⚠️ Load failed: \(file)")
                }
            }
        }
        
        // オーディオセッションの設定
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - シフトアップ（加速）
    func playShiftUpSequence(gear: Int) {
        // 💥 シフト音の設定をチェック
        if AppSettings.shared.isShiftSoundEnabled {
            if let shiftPlayer = allPlayers["shift_up"] {
                shiftPlayer.currentTime = 0
                shiftPlayer.play()
            }
        }
        
        // 💥 エンジン音の設定をチェック
        if AppSettings.shared.isEngineSoundEnabled {
            if let enginePlayer = allPlayers["engine_base"] {
                let targetRate = 0.8 + (Float(gear - 1) * 0.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    enginePlayer.stop()
                    enginePlayer.currentTime = 0
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
                downPlayer.play()
                
                revPlayer.currentTime = 0
                revPlayer.play()
            }
        }
        
        // 💥 エンジン音の設定をチェック
        if AppSettings.shared.isEngineSoundEnabled {
            if let enginePlayer = allPlayers["engine_base"] {
                let targetRate = 0.8 + (Float(gear - 1) * 0.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    enginePlayer.stop()
                    enginePlayer.currentTime = 0
                    enginePlayer.rate = min(targetRate + 0.3, 2.0)
                    enginePlayer.play()
                }
            }
        }
    }
}
