import SwiftUI

// MARK: - 🦴 1. デジタルベクター部位の定義
enum VectorMusclePart: String, CaseIterable {
    case deltoid, biceps, triceps, forearm
    case upperChest, midChest, lowerChest
    case obliques, abs, quads, calves, back
}

// MARK: - 🧍 2. シャーシ・ベクター・インジケーター (ChassisVectorIndicatorView)
struct ChassisVectorIndicatorView: View {
    var fatigueLevels: [VectorMusclePart: Double] = [:]
    
    // F1テレメトリ風カラーマッピング
    func color(for part: VectorMusclePart) -> Color {
        let level = fatigueLevels[part] ?? 0.0
        if level <= 0.0 { return .white.opacity(0.15) }
        if level <= 0.5 { return .green }
        if level <= 0.8 { return .yellow }
        return .red
    }

    var body: some View {
        HStack(spacing: 50) {
            // FRONT HUD
            VStack(spacing: 12) {
                Text("FRONT CHASSIS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.cyan.opacity(0.6))
                ZStack {
                    // 全身の電子回路風グリッド（背景）
                    BodyGridShape().stroke(Color.cyan.opacity(0.05), lineWidth: 0.5)
                    
                    // 幾何学的筋肉パーツ
                    Group {
                        VectorPart(part: .deltoid, color: color(for: .deltoid), isFront: true)
                        VectorPart(part: .upperChest, color: color(for: .upperChest), isFront: true)
                        VectorPart(part: .midChest, color: color(for: .midChest), isFront: true)
                        VectorPart(part: .lowerChest, color: color(for: .lowerChest), isFront: true)
                        VectorPart(part: .biceps, color: color(for: .biceps), isFront: true)
                        VectorPart(part: .forearm, color: color(for: .forearm), isFront: true)
                        VectorPart(part: .abs, color: color(for: .abs), isFront: true)
                        VectorPart(part: .obliques, color: color(for: .obliques), isFront: true)
                        VectorPart(part: .quads, color: color(for: .quads), isFront: true)
                    }
                }
                .frame(width: 140, height: 260)
            }
            
            // REAR HUD
            VStack(spacing: 12) {
                Text("REAR CHASSIS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.cyan.opacity(0.6))
                ZStack {
                    BodyGridShape().stroke(Color.cyan.opacity(0.05), lineWidth: 0.5)
                    
                    Group {
                        VectorPart(part: .back, color: color(for: .back), isFront: false)
                        VectorPart(part: .triceps, color: color(for: .triceps), isFront: false)
                        VectorPart(part: .deltoid, color: color(for: .deltoid), isFront: false)
                        VectorPart(part: .forearm, color: color(for: .forearm), isFront: false)
                        VectorPart(part: .calves, color: color(for: .calves), isFront: false)
                    }
                }
                .frame(width: 140, height: 260)
            }
        }
        .padding(20)
        .background(Color.clear)
    }
}

// MARK: - 🎨 幾何学パーツ描画
struct VectorPart: View {
    let part: VectorMusclePart
    let color: Color
    let isFront: Bool
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { path in
                switch part {
                case .deltoid: drawDeltoid(&path, w, h)
                case .upperChest: drawUpperChest(&path, w, h)
                case .midChest: drawMidChest(&path, w, h)
                case .lowerChest: drawLowerChest(&path, w, h)
                case .biceps: drawBiceps(&path, w, h)
                case .triceps: drawTriceps(&path, w, h)
                case .forearm: drawForearm(&path, w, h)
                case .abs: drawAbs(&path, w, h)
                case .obliques: drawObliques(&path, w, h)
                case .quads: drawQuads(&path, w, h)
                case .calves: drawCalves(&path, w, h)
                case .back: drawBack(&path, w, h)
                }
            }
            .fill(color)
            .overlay(
                Path { path in
                    // スリット（隙間）を強調するアウトライン
                    switch part {
                    case .deltoid: drawDeltoid(&path, w, h)
                    case .upperChest: drawUpperChest(&path, w, h)
                    case .midChest: drawMidChest(&path, w, h)
                    case .lowerChest: drawLowerChest(&path, w, h)
                    case .biceps: drawBiceps(&path, w, h)
                    case .triceps: drawTriceps(&path, w, h)
                    case .forearm: drawForearm(&path, w, h)
                    case .abs: drawAbs(&path, w, h)
                    case .obliques: drawObliques(&path, w, h)
                    case .quads: drawQuads(&path, w, h)
                    case .calves: drawCalves(&path, w, h)
                    case .back: drawBack(&path, w, h)
                    }
                }
                .stroke(Color.black, lineWidth: 1)
            )
        }
    }
    
    // 💥 幾何学的ポリゴン描画ロジック (w=140, h=260想定)
    private func drawDeltoid(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.22, y: h*0.14, width: w*0.12, height: h*0.06))
        p.addRect(CGRect(x: w*0.66, y: h*0.14, width: w*0.12, height: h*0.06))
    }
    private func drawUpperChest(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.38, y: h*0.16, width: w*0.11, height: h*0.025))
        p.addRect(CGRect(x: w*0.51, y: h*0.16, width: w*0.11, height: h*0.025))
    }
    private func drawMidChest(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.37, y: h*0.19, width: w*0.12, height: h*0.04))
        p.addRect(CGRect(x: w*0.51, y: h*0.19, width: w*0.12, height: h*0.04))
    }
    private func drawLowerChest(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.38, y: h*0.235, width: w*0.11, height: h*0.025))
        p.addRect(CGRect(x: w*0.51, y: h*0.235, width: w*0.11, height: h*0.025))
    }
    private func drawBiceps(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.19, y: h*0.21, width: w*0.08, height: h*0.1))
        p.addRect(CGRect(x: w*0.73, y: h*0.21, width: w*0.08, height: h*0.1))
    }
    private func drawTriceps(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.18, y: h*0.21, width: w*0.09, height: h*0.12))
        p.addRect(CGRect(x: w*0.73, y: h*0.21, width: w*0.09, height: h*0.12))
    }
    private func drawForearm(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.14, y: h*0.32, width: w*0.07, height: h*0.12))
        p.addRect(CGRect(x: w*0.79, y: h*0.32, width: w*0.07, height: h*0.12))
    }
    private func drawAbs(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        for i in 0..<3 { p.addRect(CGRect(x: w*0.45, y: h*(0.285 + Double(i)*0.045), width: w*0.1, height: h*0.035)) }
    }
    private func drawObliques(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.4, y: h*0.29, width: w*0.04, height: h*0.14))
        p.addRect(CGRect(x: w*0.56, y: h*0.29, width: w*0.04, height: h*0.14))
    }
    private func drawQuads(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.33, y: h*0.58, width: w*0.14, height: h*0.22))
        p.addRect(CGRect(x: w*0.53, y: h*0.58, width: w*0.14, height: h*0.22))
    }
    private func drawCalves(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.addRect(CGRect(x: w*0.33, y: h*0.83, width: w*0.1, height: h*0.12))
        p.addRect(CGRect(x: w*0.57, y: h*0.83, width: w*0.1, height: h*0.12))
    }
    private func drawBack(_ p: inout Path, _ w: CGFloat, _ h: CGFloat) {
        p.move(to: CGPoint(x: w*0.5, y: h*0.15))
        p.addLine(to: CGPoint(x: w*0.72, y: h*0.25))
        p.addLine(to: CGPoint(x: w*0.5, y: h*0.48))
        p.addLine(to: CGPoint(x: w*0.28, y: h*0.25))
        p.closeSubpath()
    }
}

// 💥 背景の電子回路風グリッド
struct BodyGridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 縦線
        for x in stride(from: 0, through: w, by: 20) { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: h)) }
        // 横線
        for y in stride(from: 0, through: h, by: 20) { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: w, y: y)) }
        return path
    }
}

// MARK: - 🚀 Preview (オーバーヒート状態のデモ)
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Text("TELEMETRY STATUS: OVERHEAT DETECTED").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.red)
            ChassisVectorIndicatorView(fatigueLevels: [
                .upperChest: 1.0, .midChest: 1.0, .lowerChest: 1.0, // ベンチプレス追い込み
                .triceps: 0.9, .deltoid: 0.7,
                .quads: 0.4, // スクワット軽め
                .abs: 0.0
            ])
            .frame(height: 300)
        }
    }
}
