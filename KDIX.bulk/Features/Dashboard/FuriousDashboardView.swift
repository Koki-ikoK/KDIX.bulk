import SwiftUI

// MARK: - 🏎️ Garage用：ワイスピ風 ダッシュボード (Safety Car Edition)
struct FuriousDashboardView: View {
    var currentStreak: Int = 12
    var totalVolume: Int = 34500
    var shieldCount: Int = 2
    var onShieldTapped: () -> Void = {}
    var onStartWorkout: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            Button(action: onStartWorkout) {
                SpeedometerGauge(volume: totalVolume)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            HStack(alignment: .bottom, spacing: 0) {
                TachometerGauge(streak: currentStreak)
                    .padding(.leading, 10)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("SAFETY CAR")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(shieldCount > 0 ? .yellow : .gray)
                        .shadow(color: .yellow.opacity(shieldCount > 0 ? 0.8 : 0), radius: 5)
                    
                    HStack(spacing: 12) {
                        Text("\(shieldCount)")
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(shieldCount > 0 ? .yellow : .gray)
                            .shadow(color: .yellow.opacity(shieldCount > 0 ? 0.8 : 0), radius: 8, x: 0, y: 0)
                        
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()
                            onShieldTapped()
                        }) {
                            SafetyCarIcon(isCharged: shieldCount > 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 20)
            }
        }
    }
}

// MARK: - スピードメーター（最適化サイズ）
struct SpeedometerGauge: View {
    var volume: Int
    var formattedVolume: String {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: volume)) ?? "\(volume)"
    }
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [.gray, .black, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 210, height: 210).shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 10)
            Circle().fill(RadialGradient(colors: [Color(white: 0.1), Color.black], center: .center, startRadius: 10, endRadius: 105)).frame(width: 196, height: 196)
            Circle().trim(from: 0.1, to: 0.9).stroke(Color.cyan.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 180, height: 180).rotationEffect(.degrees(90)).shadow(color: .cyan, radius: 10)
            
            ForEach(0...50, id: \.self) { i in
                let isMajor = i % 5 == 0
                Rectangle().fill(Color.cyan).frame(width: isMajor ? 3 : 1, height: isMajor ? 12 : 6).offset(y: -85).rotationEffect(.degrees((Double(i) / 50.0 * 260.0) - 130.0))
            }
            
            VStack(spacing: -5) {
                Text(formattedVolume).font(.system(size: 40, weight: .black, design: .monospaced)).foregroundColor(.cyan).shadow(color: .cyan.opacity(0.8), radius: 10, x: 0, y: 0)
                Text("kg").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.cyan.opacity(0.8))
            }.offset(y: 15)
        }
    }
}

// MARK: - タコメーター（最適化サイズ）
struct TachometerGauge: View {
    var streak: Int
    let maxStreak: Int = 30
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [.gray, .black, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 130, height: 130).shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 8)
            Circle().fill(RadialGradient(colors: [Color(white: 0.15), Color.black], center: .center, startRadius: 5, endRadius: 65)).frame(width: 118, height: 118)
            
            ForEach(0...40, id: \.self) { i in
                let isMajor = i % 5 == 0
                Rectangle().fill(i >= 30 ? Color.red : Color.cyan).frame(width: isMajor ? 2 : 1, height: isMajor ? 10 : 5).offset(y: -52).rotationEffect(.degrees((Double(i) / 40.0 * 260.0) - 130.0))
            }
            
            ForEach(0...8, id: \.self) { index in
                let angleRad = ((Double(index * 5) / 40.0 * 260.0) - 130.0) * .pi / 180.0
                Text("\(index + 1)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(index + 1 >= 7 ? .red : .white).offset(x: CGFloat(sin(angleRad)) * 38, y: -CGFloat(cos(angleRad)) * 38)
            }
            
            VStack(spacing: 0) {
                Text("\(streak) 日").font(.system(size: 16, weight: .black, design: .monospaced)).foregroundColor(.cyan).shadow(color: .cyan, radius: 4).padding(.horizontal, 8).padding(.vertical, 4).background(Color.black.opacity(0.6).cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.3))))
            }.offset(y: -15)
            
            Needle(value: min(Double(streak), Double(maxStreak)), maxValue: Double(maxStreak)).shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 3).frame(width: 130, height: 130)
            Circle().fill(LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom)).frame(width: 16, height: 16)
        }
    }
}

// MARK: - メーターの針
struct Needle: View {
    var value: Double
    var maxValue: Double
    var needleRotation: Angle { return .degrees((min(max(value, 0), maxValue) / maxValue) * 260.0 - 130.0) }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let w = geometry.size.width, h = geometry.size.height
                path.move(to: CGPoint(x: w * 0.46, y: h * 0.5)); path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.18)); path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.5)); path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.55))
            }.fill(Color.red)
        }
        .rotationEffect(needleRotation).animation(.spring(response: 1.0, dampingFraction: 0.7), value: value)
    }
}

// MARK: - 🏎️ SafetyCarIcon
struct SafetyCarIcon: View {
    var isCharged: Bool
    var body: some View {
        ZStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 24))
                .foregroundColor(isCharged ? .yellow : .gray)
            if isCharged {
                Image(systemName: "car.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
                    .offset(y: 2)
            }
        }
        .frame(width: 40, height: 40)
        .background(isCharged ? Color.yellow.opacity(0.2) : Color.white.opacity(0.05))
        .clipShape(Circle())
    }
}

