
import Foundation
import AVFoundation
import Combine
import SwiftUI

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable{
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP") // 日本語
        utterance.rate = 0.55 // 読み上げスピード
        
        do {
            // 🌟 ここが魔法のコード！
            // .duckOthers = 他のアプリの音（音楽）を一時的に下げる
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
            
            // セッションをオンにして喋り始める
            try AVAudioSession.sharedInstance().setActive(true)
            synthesizer.speak(utterance)
        } catch {
            print("音声セッションの起動に失敗しました: \(error)")
        }
    }
    
    // 🌟 喋り終わったら自動で呼ばれるメソッド
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            // セッションをオフにして、音楽の音量を元に戻す
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("音声セッションの終了に失敗しました: \(error)")
        }
    }
}
