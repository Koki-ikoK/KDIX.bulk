import SwiftUI

// MARK: - 🦶 9. アクセルペダル View (加速＆レブリミッター振動 搭載版)
struct WorkoutStartPedalView: View {
    let activeNeonColor: Color
    let isSelected: Bool
    var onComplete: () -> Void
    
    @State private var pressProgress: CGFloat = 0.0
    @State private var isPressing: Bool = false
    @State private var isRedZoneFlash: Bool = false
    @State private var timer: Timer? = nil
    
    // 👇 レッドゾーンでのバウンド回数をカウント
    @State private var revCount: Int = 0 
    
    var body: some View {
        VStack(spacing: 16) {
            
            // 1. タコメーター
            MiniTachometerView(progress: pressProgress, activeColor: activeNeonColor, isFlashing: isRedZoneFlash)
                .scaleEffect(isPressing ? 1.05 : 1.0)
                .animation(.spring(), value: isPressing)
            
            // 2. アクセルペダル本体
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 90, height: 160)
                        .offset(y: 10)
                        .blur(radius: 5)

                    // Liquid Glass ペダル
                    RoundedRectangle(cornerRadius: 15)
                        .fill(LinearGradient(colors: [Color(white: 0.15), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 90, height: 160)
                        .overlay(PedalRubberDots())
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                                .blendMode(.overlay)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(isSelected ? activeNeonColor.opacity(0.5) : .gray.opacity(0.2), lineWidth: 1)
                        )
                        .rotation3DEffect(.degrees(isPressing ? 25 : 0), axis: (x: 1, y: 0, z: 0), anchor: .bottom)
                        .scaleEffect(isPressing ? 0.95 : 1.0)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if isSelected && !isPressing { startPressing() }
                        }
                        .onEnded { _ in stopPressing() }
                )
                
                // 文言
                Text(isSelected ? "アクセルを踏んでワークアウトスタート" : "ワークアウトを選択してください")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .italic()
                    .foregroundColor(isSelected ? (isPressing ? activeNeonColor : .white) : .gray.opacity(0.5))
                    .shadow(color: isPressing ? activeNeonColor.opacity(0.5) : .clear, radius: 5)
                    .animation(.easeInOut, value: isSelected)
                    .tracking(1)
            }
        }
        .padding(.bottom, 20)
    }
    
    private func startPressing() {
        isPressing = true
        revCount = 0
        ProSoundManager.shared.startEngine()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            // 🏎️ まだMAXに到達していない時
            if pressProgress < 1.0 && revCount == 0 {
                // 踏み込み速度を劇的にアップ (0.015 -> 0.04) 約0.5秒でMAX！
                pressProgress += 0.04
                
                ProSoundManager.shared.setVolume(Float(pressProgress))
                
                if Int(pressProgress * 100) % 10 == 0 {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: pressProgress)
                }
                
                if pressProgress > 0.8 {
                    withAnimation(.easeInOut(duration: 0.1)) { isRedZoneFlash.toggle() }
                }
            } else {
                // 💥 MAX到達時：レッドゾーンで針を激しく振動させる（レブリミッター）
                revCount += 1
                
                // 針を 0.96 〜 1.04 の間でランダムにバウンドさせる
                withAnimation(.linear(duration: 0.02)) {
                    pressProgress = CGFloat.random(in: 0.96...1.04)
                }
                
                // ガガガガッ！というエンジンの吹け切った振動
                if revCount % 2 == 0 {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
                }
                
                // 約0.4秒間 (20回) 振動したら発進！
                if revCount >= 20 {
                    pressProgress = 1.0 // 針をMAXで固定
                    completeLaunch()
                }
            }
        }
    }
    
    private func stopPressing() {
        isPressing = false
        isRedZoneFlash = false
        revCount = 0
        timer?.invalidate()
        timer = nil
        ProSoundManager.shared.stopEngine()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { pressProgress = 0 }
    }
    
    private func completeLaunch() {
        timer?.invalidate()
        timer = nil
        ProSoundManager.shared.playShiftImpact()
        onComplete()
    }
}

// MARK: - ⏱ 10. リアル・タコメーター View
struct MiniTachometerView: View {
    var progress: CGFloat // 0.0 ~ 1.0
    var activeColor: Color
    var isFlashing: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 150, height: 150)
                .shadow(color: isFlashing ? .red : .black.opacity(0.8), radius: isFlashing ? 15 : 10)
            
            Circle()
                .fill(Color.black)
                .frame(width: 110, height: 110)
            
            ForEach(1...9, id: \.self) { i in
                let angle = Angle(degrees: -120 + Double(i - 1) * 30.0)
                let isRedZone = i >= 7
                let tickColor = isRedZone ? Color.red : activeColor
                
                Rectangle()
                    .fill(tickColor)
                    .frame(width: 2, height: 8)
                    .offset(y: -50)
                    .rotationEffect(angle)
                
                VStack {
                    Text("\(i)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(isRedZone ? .red : .white)
                        .rotationEffect(-angle)
                    Spacer()
                }
                .frame(height: 136)
                .rotationEffect(angle)
            }
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 3, height: 60)
                .offset(y: -25)
                .rotationEffect(Angle(degrees: -120 + Double(progress) * 240))
                .shadow(color: .red, radius: 5)
            
            Circle().fill(Color(white: 0.4)).frame(width: 12, height: 12)
            
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: 90, height: 45)
                .offset(y: -25)
        }
    }
}

// MARK: - 🔘 11. ペダルの滑り止めドット
struct PedalRubberDots: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle().fill(Color.black.opacity(0.8)).frame(width: 10, height: 10)
                    Circle().fill(Color.black.opacity(0.8)).frame(width: 10, height: 10)
                }
            }
        }
    }
}
