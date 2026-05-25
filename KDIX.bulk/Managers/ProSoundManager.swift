import Foundation
import AVFoundation

// MARK: - 🎵 プロ仕様サウンドマネージャー（音量制御・ミキシング対応）
class ProSoundManager {
    static let shared = ProSoundManager()
    private var enginePlayer: AVAudioPlayer?
    
    private init() {
        // オーディオセッションの設定（他アプリの音を止めない）
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        if let url = Bundle.main.url(forResource: "engine_rev", withExtension: "mp3") {
            enginePlayer = try? AVAudioPlayer(contentsOf: url)
            enginePlayer?.numberOfLoops = -1 // ループ再生
            enginePlayer?.prepareToPlay()
        }
    }
    
    func startEngine() {
        guard AppSettings.shared.isEngineSoundEnabled else { return }
        enginePlayer?.volume = 0.0
        enginePlayer?.play()
        enginePlayer?.setVolume(1.0, fadeDuration: 0.5)
    }
    
    func setVolume(_ volume: Float) {
        enginePlayer?.volume = volume
    }
    
    func stopEngine() {
        enginePlayer?.setVolume(0, fadeDuration: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.enginePlayer?.stop()
        }
    }
    
    func playShiftImpact() {
        guard AppSettings.shared.isShiftSoundEnabled else { return }
        AudioServicesPlaySystemSound(1521)
    }
}
