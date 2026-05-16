import AVFoundation

// MARK: - 音を管理するサウンドマネージャー（マナーモード貫通仕様）
class SoundManager {
    // アプリ全体で1つのマネージャーを共有する
    static let shared = SoundManager()
    
    // 👇 さっき迷子になっていた「player」はここにいます
    var player: AVAudioPlayer?
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🚨 オーディオセッションの設定に失敗しました")
        }
    }
    
    // 🏎️ エンジンスタート用
    func playEngineSound() {
        guard let url = Bundle.main.url(forResource: "engine", withExtension: "mp3") else {
            print("🚨 engine.mp3 が見つかりません！")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch { print("音の再生に失敗しました") }
    }
    
    // ⚡️ QUICK START用（タイヤのスキール音）
    func playSquealSound() {
        guard let url = Bundle.main.url(forResource: "Squeal", withExtension: "mp3") else {
            print("🚨 Squeal.mp3 が見つかりません！Target Membershipを確認してください。")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch { print("音の再生に失敗しました") }
    }
    
    // 🔧 CUSTOM用（ソケットレンチ音）
    func playSocketWrenchSound() {
        guard let url = Bundle.main.url(forResource: "SocketWrench", withExtension: "mp3") else {
            print("🚨 SocketWrench.mp3 が見つかりません！Target Membershipを確認してください。")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch { print("音の再生に失敗しました") }
    }
}
