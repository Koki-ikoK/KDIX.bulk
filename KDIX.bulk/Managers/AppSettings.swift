import SwiftUI
import Combine

// MARK: - 🛠️ アプリ全体の設定管理 (シングルトン)
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var isEngineSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isEngineSoundEnabled, forKey: "isEngineSoundEnabled") }
    }
    
    @Published var isShiftSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isShiftSoundEnabled, forKey: "isShiftSoundEnabled") }
    }
    
    @Published var isHapticEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticEnabled, forKey: "isHapticEnabled") }
    }
    
    private init() {
        self.isEngineSoundEnabled = UserDefaults.standard.object(forKey: "isEngineSoundEnabled") as? Bool ?? true
        self.isShiftSoundEnabled = UserDefaults.standard.object(forKey: "isShiftSoundEnabled") as? Bool ?? true
        self.isHapticEnabled = UserDefaults.standard.object(forKey: "isHapticEnabled") as? Bool ?? true
    }
}

// MARK: - 🏁 共通：カーボンファイバー背景
struct CarbonFiberBackground: View {
    var opacity: Double = 0.3
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CarbonFiberCanvasView().opacity(opacity).ignoresSafeArea()
        }
    }
}

struct CarbonFiberCanvasView: View {
    var body: some View {
        Canvas { context, size in
            let patternSize: CGFloat = 8
            for x in stride(from: 0, through: size.width, by: patternSize) {
                for y in stride(from: 0, through: size.height, by: patternSize) {
                    let rect = CGRect(x: x, y: y, width: patternSize - 1, height: patternSize - 1)
                    var path = Path(rect)
                    context.fill(path, with: .color(Color(white: 0.15)))
                    
                    let subRect = CGRect(x: x + 2, y: y + 2, width: patternSize - 5, height: patternSize - 5)
                    context.fill(Path(subRect), with: .color(Color(white: 0.05)))
                }
            }
        }
    }
}
