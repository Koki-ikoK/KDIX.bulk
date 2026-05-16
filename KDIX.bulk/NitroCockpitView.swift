import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AudioToolbox
import AVFoundation
import Combine

// MARK: - 🚀 19. ニトロコックピット画面 (Movie-Quality Hyper Drive Version)
struct NitroCockpitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var nitroManager = NitroManager.shared
    
    // 💥 3つの点火フェーズの状態
    @State private var isValveOpen = false
    @State private var isArmed = false
    @State private var isFiring = false
    
    // 演出用
    @State private var showSuccess = false
    @State private var shakeOffset: CGFloat = 0
    @State private var shakeAngle: Double = 0 // 💥 傾き（横G）
    @State private var steeringScale: CGFloat = 1.0
    @State private var flashOpacity: Double = 0.0
    @State private var toggleShake: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 1. 💥 圧倒的スピード感！ハイパースペースワープ背景
            HyperspaceEffect(isFiring: isFiring)
                .ignoresSafeArea()
            
            // 2. 💥 画面のフチが青く燃える（ビネット効果）
            RadialGradient(colors: [.clear, .clear, .cyan.opacity(isFiring ? 0.6 : 0.0)], center: .center, startRadius: 100, endRadius: 500)
                .ignoresSafeArea()
                .blendMode(.screen)
            
            // 3. 青い強烈な反射光
            LinearGradient(colors: [.cyan.opacity(0.9), .clear], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea().opacity(flashOpacity).blendMode(.screen)
            
            VStack {
                // 上部パネル（バルブとスイッチ）
                HStack(alignment: .top) {
                    NOSValvePanel(isValveOpen: $isValveOpen)
                    Spacer()
                    AviationToggle(isOn: $isArmed, isValveOpen: isValveOpen)
                        .offset(x: toggleShake)
                        .onChange(of: isArmed) { armed in
                            if armed && !isValveOpen {
                                isArmed = false
                                if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { toggleShake = 10 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { toggleShake = 0 }
                            } else if armed {
                                if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                .shadow(color: .black.opacity(0.7), radius: 10, y: 5)
                        )
                        .overlay(VStack { HStack { BoltView(); Spacer(); BoltView() }; Spacer(); HStack { BoltView(); Spacer(); BoltView() } }.padding(6))
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .zIndex(2)
                
                Spacer()
                
                // 🏎️ リアルな3Dレーシングステアリング
                ZStack(alignment: .center) {
                    // 💥 Gフォース・ゴースト（激しい振動による赤と青の色ズレ残像）
                    if isFiring {
                        RacingSteeringWheel(isArmed: isArmed, isFiring: isFiring, fireNitro: {})
                            .offset(x: shakeOffset * 1.5, y: -shakeOffset)
                            .opacity(0.4)
                            .colorMultiply(.red)
                            .blendMode(.screen)
                        
                        RacingSteeringWheel(isArmed: isArmed, isFiring: isFiring, fireNitro: {})
                            .offset(x: -shakeOffset * 1.5, y: shakeOffset)
                            .opacity(0.4)
                            .colorMultiply(.cyan)
                            .blendMode(.screen)
                    }
                    
                    // 本体
                    RacingSteeringWheel(isArmed: isArmed, isFiring: isFiring) {
                        fireNitro()
                    }
                    .shadow(color: isFiring ? .cyan.opacity(0.5) : .black.opacity(0.8), radius: isFiring ? 30 : 20, y: 15)
                }
                .scaleEffect(steeringScale)
                .rotationEffect(.degrees(shakeAngle)) // 💥 ガタガタ傾く！
                .offset(x: shakeOffset, y: shakeOffset / 2)
                .padding(.bottom, -30)
                .zIndex(1)
            }
            
            // 4. 💥 成功メッセージ（奥からドカン！と叩きつけるアニメーション）
            if showSuccess {
                VStack(spacing: 10) {
                    Text("SYSTEM OVERRIDE")
                        .font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                    Text("STREAK SAVED")
                        .font(.system(size: 44, weight: .heavy, design: .rounded)).foregroundColor(.white)
                }
                .shadow(color: .cyan, radius: 25)
                .transition(.asymmetric(
                    insertion: .scale(scale: 4.0).combined(with: .opacity), // 4倍の大きさからドカン！
                    removal: .opacity
                ))
                .zIndex(10)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32)).symbolRenderingMode(.palette).foregroundStyle(Color(white: 0.8), Color.black.opacity(0.5))
                            .padding(.top, 16).padding(.trailing, 24)
                    }
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // 💥 限界突破のニトロ噴射ロジック
    private func fireNitro() {
        guard isValveOpen, isArmed, !isFiring else { return }
        
        isFiring = true
        if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
        
        // 瞬間的なG（奥に引き込まれる）
        withAnimation(.easeIn(duration: 0.15)) {
            steeringScale = 0.80
            flashOpacity = 1.0
        }
        
        // 激しい振動とシェイク（傾き追加）
        let shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0) }
            withAnimation(.linear(duration: 0.04)) {
                shakeOffset = CGFloat.random(in: -20...20)
                shakeAngle = Double.random(in: -3...3) // 横Gの傾き
                flashOpacity = Double.random(in: 0.4...1.0)
            }
        }
        
        // 2秒後に収束
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            shakeTimer.invalidate()
            withAnimation(.easeOut(duration: 1.0)) {
                isFiring = false
                steeringScale = 1.0
                shakeOffset = 0
                shakeAngle = 0
                flashOpacity = 0.0
            }
            _ = nitroManager.useNitro(for: Calendar.current.startOfDay(for: Date()))
            
            // ドカン！とメッセージを叩きつける
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { showSuccess = true }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
        }
    }
}

// MARK: - 💥 圧倒的ワープエフェクト背景
struct HyperspaceEffect: View {
    var isFiring: Bool
    
    var body: some View {
        ZStack {
            Color.black
            
            // 発射時のみ、放射状のリングが爆速で手前に拡大してくる
            if isFiring {
                ForEach(0..<40, id: \.self) { i in
                    Circle()
                        // 点線のリングで流星を表現
                        .stroke(Color.cyan.opacity(Double.random(in: 0.2...0.8)), style: StrokeStyle(lineWidth: CGFloat.random(in: 2...8), dash: [CGFloat.random(in: 50...200), CGFloat.random(in: 20...100)]))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                        // 最初は小さく、10倍のサイズに拡大（手前に来る演出）
                        .modifier(WarpAnimationModifier(delay: Double.random(in: 0...0.4), duration: Double.random(in: 0.2...0.5)))
                }
            }
        }
    }
}

// 💥 ワープアニメーション用のモディファイア（繰り返し拡大）
struct WarpAnimationModifier: ViewModifier {
    let delay: Double
    let duration: Double
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeIn(duration: duration).repeatForever(autoreverses: false)) {
                        scale = 25.0 // 一気に画面外まで拡大
                        opacity = 1.0
                    }
                }
            }
    }
}

// MARK: - 🎛 リアルUIパーツ群

struct AviationToggle: View {
    @Binding var isOn: Bool
    var isValveOpen: Bool
    var body: some View {
        VStack(spacing: 8) {
            Circle().fill(isOn ? Color.green : Color.gray.opacity(0.3)).frame(width: 14, height: 14).shadow(color: isOn ? .green : .clear, radius: 5)
            Text(isOn ? "ON" : "SAFE").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(isOn ? .green : .gray).shadow(color: isOn ? .green : .clear, radius: 5)
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.4)], startPoint: .top, endPoint: .bottom)).frame(width: 36, height: 36).overlay(Circle().stroke(Color.black, lineWidth: 2))
                Capsule().fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.3)], startPoint: .leading, endPoint: .trailing)).frame(width: 12, height: 40).offset(y: isOn ? -12 : 12).shadow(color: .black.opacity(0.6), radius: 3, y: isOn ? 5 : -5).animation(.spring(response: 0.3, dampingFraction: 0.5), value: isOn)
            }.frame(height: 60).onTapGesture { isOn.toggle() }.opacity(isValveOpen ? 1.0 : 0.5)
        }
    }
}

struct NOSValvePanel: View {
    @Binding var isValveOpen: Bool
    @State private var rotation: Double = 0
    @State private var lastRotation: Double = 0
    var body: some View {
        VStack(spacing: 16) {
            Text("N2O VALVE").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(isValveOpen ? .cyan : .gray).shadow(color: isValveOpen ? .cyan : .clear, radius: 5)
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(white: 0.3), Color(white: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 90, height: 90).overlay(Circle().stroke(Color.black, lineWidth: 2))
                Circle().trim(from: 0, to: CGFloat(rotation / 360)).stroke(isValveOpen ? Color.cyan : Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round)).frame(width: 106, height: 106).rotationEffect(.degrees(-90)).shadow(color: isValveOpen ? .cyan : .clear, radius: 5)
                Image(systemName: "gearshape.fill").font(.system(size: 80)).foregroundStyle(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.4)], startPoint: .top, endPoint: .bottom)).shadow(color: .black.opacity(0.8), radius: 5, y: 3).rotationEffect(.degrees(rotation)).gesture(DragGesture().onChanged { value in guard !isValveOpen else { return }; let dragAmount = value.translation.height + value.translation.width; var newRotation = lastRotation + Double(dragAmount); if newRotation < 0 { newRotation = 0 }; if newRotation >= 360 { newRotation = 360 }; rotation = newRotation; if Int(rotation) % 40 == 0 && AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }; if rotation == 360 { if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }; withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isValveOpen = true } } }.onEnded { _ in if !isValveOpen { withAnimation(.easeOut(duration: 0.5)) { rotation = 0; lastRotation = 0 } } })
                Circle().fill(Color.black).frame(width: 20, height: 20)
            }
            Text(isValveOpen ? "PRESSURE MAX" : "CLOSED").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(isValveOpen ? .cyan : .red)
        }.padding(20).background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3), lineWidth: 1))).overlay(VStack { HStack { BoltView(); Spacer(); BoltView() }; Spacer(); HStack { BoltView(); Spacer(); BoltView() } }.padding(6))
    }
}

struct RacingSteeringWheel: View {
    var isArmed: Bool
    var isFiring: Bool
    var fireNitro: () -> Void
    var body: some View {
        ZStack {
            Circle().strokeBorder(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 45).frame(width: 360, height: 360).overlay(Circle().stroke(Color.black.opacity(0.8), lineWidth: 2))
            Circle().stroke(Color.yellow.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])).frame(width: 282, height: 282)
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: [Color(white: 0.25), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)).frame(width: 140, height: 60).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 2)).offset(x: -100, y: 15).rotationEffect(.degrees(15))
                RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: [Color(white: 0.25), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)).frame(width: 140, height: 60).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 2)).offset(x: 100, y: 15).rotationEffect(.degrees(-15))
                RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .top, endPoint: .bottom)).frame(width: 50, height: 130).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 2)).offset(y: 110)
            }.shadow(color: .black.opacity(0.7), radius: 5, y: 5)
            Circle().fill(RadialGradient(colors: [Color(white: 0.15), Color.black], center: .center, startRadius: 10, endRadius: 70)).frame(width: 140, height: 140).overlay(Circle().stroke(Color.black, lineWidth: 2)).shadow(color: .black.opacity(0.9), radius: 8, y: 5)
            Text("GARAGE").font(.system(size: 16, weight: .black, design: .monospaced)).foregroundColor(.yellow).tracking(3)
            ForEach(0..<6) { i in Circle().fill(LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 10, height: 10).offset(y: -55).rotationEffect(.degrees(Double(i) * 60)) }
            SmallRedButton(isArmed: isArmed, isFiring: isFiring, action: fireNitro).offset(x: -95, y: 0)
            SmallRedButton(isArmed: isArmed, isFiring: isFiring, action: fireNitro).offset(x: 95, y: 0)
        }.frame(width: 360, height: 360)
    }
}

struct SmallRedButton: View {
    var isArmed: Bool; var isFiring: Bool; var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.gray).frame(width: 34, height: 34).shadow(color: .black, radius: 2, y: 1)
                Circle().fill(Color.black).frame(width: 28, height: 28)
                Circle().fill(RadialGradient(colors: [isArmed ? .red : Color(red: 0.5, green: 0, blue: 0), Color(red: 0.2, green: 0, blue: 0)], center: .top, startRadius: 2, endRadius: 15)).frame(width: 24, height: 24).shadow(color: isArmed ? .red : .clear, radius: isArmed ? 8 : 0)
                Ellipse().fill(Color.white.opacity(0.5)).frame(width: 14, height: 6).offset(y: -6)
            }
            .scaleEffect(isFiring ? 0.85 : 1.0).animation(.spring(response: 0.2, dampingFraction: 0.4), value: isFiring)
        }.disabled(!isArmed || isFiring)
    }
}

struct BoltView: View { var body: some View { Circle().fill(LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 8, height: 8).shadow(color: .black.opacity(0.8), radius: 1) } }

// MARK: - 💥 ニトロマネージャー
class NitroManager: ObservableObject {
    static let shared = NitroManager()
    @Published var nitrousCount: Int { didSet { UserDefaults.standard.set(nitrousCount, forKey: "nitrousCount") } }
    @Published var usedNitroDates: [Date] { didSet { if let data = try? JSONEncoder().encode(usedNitroDates) { UserDefaults.standard.set(data, forKey: "usedNitroDates") } } }
    private init() {
        UserDefaults.standard.register(defaults: ["nitrousCount": 2])
        self.nitrousCount = UserDefaults.standard.integer(forKey: "nitrousCount")
        if let data = UserDefaults.standard.data(forKey: "usedNitroDates"), let dates = try? JSONDecoder().decode([Date].self, from: data) { self.usedNitroDates = dates } else { self.usedNitroDates = [] }
    }
    func useNitro(for date: Date) -> Bool {
        guard nitrousCount > 0 else { return false }
        nitrousCount -= 1; usedNitroDates.append(date); return true
    }
}
