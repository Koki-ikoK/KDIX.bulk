import SwiftUI

// MARK: - 🦴 1. 筋肉部位の定義 (全12部位)
enum MusclePartType: String, CaseIterable {
    case deltoid     // 三角筋
    case biceps      // 上腕二頭筋
    case triceps     // 上腕三頭筋
    case forearm     // 前腕
    case upperChest  // 上部胸筋
    case midChest    // 中部胸筋
    case lowerChest  // 下部胸筋
    case obliques    // 腹斜筋
    case abs         // 腹直筋
    case quads       // 大腿四頭筋
    case calves      // 脹脛
    case back        // 背中
    
    var label: String {
        switch self {
        case .deltoid: return "三角筋"
        case .biceps: return "二頭筋"
        case .triceps: return "三頭筋"
        case .forearm: return "前腕"
        case .upperChest: return "胸筋上部"
        case .midChest: return "胸筋中部"
        case .lowerChest: return "胸筋下部"
        case .obliques: return "腹斜筋"
        case .abs: return "腹直筋"
        case .quads: return "大腿四頭筋"
        case .calves: return "脹脛"
        case .back: return "背筋"
        }
    }
}

// MARK: - 🧍 2. シャーシ診断：筋肉ヒートマップ (ChassisDiagnosticsView)
struct ChassisDiagnosticsView: View {
    // 各部位の疲労度 (0.0 - 1.0)
    // 今回は初期化としてすべて0.0（白）に設定
    var fatigueLevels: [MusclePartType: Double] = {
        var dict: [MusclePartType: Double] = [:]
        for part in MusclePartType.allCases { dict[part] = 0.0 }
        return dict
    }()
    
    // カラーマッピング関数
    func getFatigueColor(for level: Double) -> Color {
        if level <= 0.0 { return .white } // 初期状態: 白
        if level >= 1.0 { return .red }
        if level >= 0.7 { return .orange }
        if level >= 0.4 { return .yellow }
        if level >= 0.2 { return .green }
        return .white
    }

    var body: some View {
        VStack(spacing: 24) {
            // ヘッダー
            HStack {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(.cyan)
                Text("CHASSIS DIAGNOSTICS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("CONDITION: NOMINAL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green.opacity(0.8))
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 40) {
                // 正面図 (Front View)
                VStack(spacing: 12) {
                    Text("FRONT").font(.system(size: 8, weight: .black)).foregroundColor(.gray)
                    ZStack {
                        // ベースシルエット
                        HumanBodyPath(isFront: true)
                            .fill(Color.white.opacity(0.1))
                        
                        // 各パーツの重ね合わせ（.colorMultiplyを使用）
                        ForEach(MusclePartType.allCases, id: \.self) { part in
                            if isFrontPart(part) {
                                MusclePathBuilder(part: part, isFront: true)
                                    .colorMultiply(getFatigueColor(for: fatigueLevels[part] ?? 0.0))
                            }
                        }
                        
                        // 輪郭
                        HumanBodyPath(isFront: true)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .frame(width: 140, height: 280)
                }
                
                // 背面図 (Rear View)
                VStack(spacing: 12) {
                    Text("REAR").font(.system(size: 8, weight: .black)).foregroundColor(.gray)
                    ZStack {
                        HumanBodyPath(isFront: false)
                            .fill(Color.white.opacity(0.1))
                        
                        ForEach(MusclePartType.allCases, id: \.self) { part in
                            if isRearPart(part) {
                                MusclePathBuilder(part: part, isFront: false)
                                    .colorMultiply(getFatigueColor(for: fatigueLevels[part] ?? 0.0))
                            }
                        }
                        
                        HumanBodyPath(isFront: false)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .frame(width: 140, height: 280)
                }
            }
            .padding(.bottom, 10)
        }
        .padding(24)
        .background(Color(white: 0.08).opacity(0.9))
        .cornerRadius(32)
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
    
    // 正面・背面のパーツ切り分け
    private func isFrontPart(_ part: MusclePartType) -> Bool {
        return part != .back && part != .triceps
    }
    
    private func isRearPart(_ part: MusclePartType) -> Bool {
        return part == .back || part == .triceps || part == .deltoid || part == .calves || part == .forearm
    }
}

// MARK: - 🎨 筋肉パス・ビルダー
struct MusclePathBuilder: View {
    let part: MusclePartType
    let isFront: Bool
    
    var body: some View {
        Group {
            switch part {
            case .deltoid: DeltoidPath(isFront: isFront).fill(.white)
            case .biceps: BicepsPath().fill(.white)
            case .triceps: TricepsPath().fill(.white)
            case .forearm: ForearmPath(isFront: isFront).fill(.white)
            case .upperChest: UpperChestPath().fill(.white)
            case .midChest: MidChestPath().fill(.white)
            case .lowerChest: LowerChestPath().fill(.white)
            case .obliques: ObliquesPath().fill(.white)
            case .abs: AbsPath().fill(.white)
            case .quads: QuadsPath().fill(.white)
            case .calves: CalvesPath(isFront: isFront).fill(.white)
            case .back: BackLatsPath().fill(.white)
            }
        }
    }
}

// MARK: - 📐 詳細な Shape 定義 (12部位)

struct HumanBodyPath: Shape {
    var isFront: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w*0.42, y: h*0.02, width: w*0.16, height: h*0.07))
        path.move(to: CGPoint(x: w*0.5, y: h*0.11))
        path.addCurve(to: CGPoint(x: w*0.75, y: h*0.15), control1: CGPoint(x: w*0.6, y: h*0.11), control2: CGPoint(x: w*0.7, y: h*0.12))
        path.addCurve(to: CGPoint(x: w*0.9, y: h*0.35), control1: CGPoint(x: w*0.85, y: h*0.2), control2: CGPoint(x: w*0.95, y: h*0.25))
        path.addCurve(to: CGPoint(x: w*0.8, y: h*0.45), control1: CGPoint(x: w*0.9, y: h*0.4), control2: CGPoint(x: w*0.85, y: h*0.45))
        path.addCurve(to: CGPoint(x: w*0.65, y: h*0.25), control1: CGPoint(x: w*0.75, y: h*0.4), control2: CGPoint(x: w*0.7, y: h*0.35))
        path.addCurve(to: CGPoint(x: w*0.62, y: h*0.55), control1: CGPoint(x: w*0.65, y: h*0.4), control2: CGPoint(x: w*0.65, y: h*0.5))
        path.addCurve(to: CGPoint(x: w*0.72, y: h*0.96), control1: CGPoint(x: w*0.6, y: h*0.7), control2: CGPoint(x: w*0.75, y: h*0.85))
        path.addLine(to: CGPoint(x: w*0.56, y: h*0.96))
        path.addCurve(to: CGPoint(x: w*0.5, y: h*0.65), control1: CGPoint(x: w*0.55, y: h*0.85), control2: CGPoint(x: w*0.52, y: h*0.75))
        path.addCurve(to: CGPoint(x: w*0.44, y: h*0.96), control1: CGPoint(x: w*0.48, y: h*0.75), control2: CGPoint(x: w*0.45, y: h*0.85))
        path.addLine(to: CGPoint(x: w*0.28, y: h*0.96))
        path.addCurve(to: CGPoint(x: w*0.38, y: h*0.55), control1: CGPoint(x: w*0.25, y: h*0.85), control2: CGPoint(x: w*0.4, y: h*0.7))
        path.addCurve(to: CGPoint(x: w*0.35, y: h*0.25), control1: CGPoint(x: w*0.35, y: h*0.5), control2: CGPoint(x: w*0.35, y: h*0.4))
        path.addCurve(to: CGPoint(x: w*0.2, y: h*0.45), control1: CGPoint(x: w*0.3, y: h*0.35), control2: CGPoint(x: w*0.25, y: h*0.4))
        path.addCurve(to: CGPoint(x: w*0.1, y: h*0.35), control1: CGPoint(x: w*0.15, y: h*0.45), control2: CGPoint(x: w*0.1, y: h*0.4))
        path.addCurve(to: CGPoint(x: w*0.25, y: h*0.15), control1: CGPoint(x: w*0.05, y: h*0.25), control2: CGPoint(x: w*0.15, y: h*0.2))
        path.addCurve(to: CGPoint(x: w*0.5, y: h*0.11), control1: CGPoint(x: w*0.3, y: h*0.12), control2: CGPoint(x: w*0.4, y: h*0.11))
        return path
    }
}

// 部位別Shape (簡易プロトタイプ描画ロジック)
struct DeltoidPath: Shape {
    var isFront: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w*0.22, y: h*0.13, width: w*0.12, height: h*0.08))
        path.addEllipse(in: CGRect(x: w*0.66, y: h*0.13, width: w*0.12, height: h*0.08))
        return path
    }
}

struct BicepsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRoundedRect(in: CGRect(x: w*0.19, y: h*0.22, width: w*0.08, height: h*0.1), cornerSize: CGSize(width: 4, height: 4))
        path.addRoundedRect(in: CGRect(x: w*0.73, y: h*0.22, width: w*0.08, height: h*0.1), cornerSize: CGSize(width: 4, height: 4))
        return path
    }
}

struct TricepsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.21, width: w*0.09, height: h*0.12), cornerSize: CGSize(width: 4, height: 4))
        path.addRoundedRect(in: CGRect(x: w*0.73, y: h*0.21, width: w*0.09, height: h*0.12), cornerSize: CGSize(width: 4, height: 4))
        return path
    }
}

struct ForearmPath: Shape {
    var isFront: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRoundedRect(in: CGRect(x: w*0.14, y: h*0.33, width: w*0.07, height: h*0.1), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: w*0.79, y: h*0.33, width: w*0.07, height: h*0.1), cornerSize: CGSize(width: 3, height: 3))
        return path
    }
}

struct UpperChestPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRect(CGRect(x: w*0.38, y: h*0.17, width: w*0.11, height: h*0.02))
        path.addRect(CGRect(x: w*0.51, y: h*0.17, width: w*0.11, height: h*0.02))
        return path
    }
}

struct MidChestPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRect(CGRect(x: w*0.37, y: h*0.19, width: w*0.12, height: h*0.04))
        path.addRect(CGRect(x: w*0.51, y: h*0.19, width: w*0.12, height: h*0.04))
        return path
    }
}

struct LowerChestPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRect(CGRect(x: w*0.38, y: h*0.23, width: w*0.11, height: h*0.02))
        path.addRect(CGRect(x: w*0.51, y: h*0.23, width: w*0.11, height: h*0.02))
        return path
    }
}

struct ObliquesPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRect(CGRect(x: w*0.4, y: h*0.3, width: w*0.04, height: h*0.12))
        path.addRect(CGRect(x: w*0.56, y: h*0.3, width: w*0.04, height: h*0.12))
        return path
    }
}

struct AbsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        for i in 0..<3 {
            path.addRoundedRect(in: CGRect(x: w*0.45, y: h*(0.28 + Double(i)*0.04), width: w*0.1, height: h*0.03), cornerSize: CGSize(width: 2, height: 2))
        }
        return path
    }
}

struct QuadsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRoundedRect(in: CGRect(x: w*0.33, y: h*0.6, width: w*0.14, height: h*0.2), cornerSize: CGSize(width: 8, height: 8))
        path.addRoundedRect(in: CGRect(x: w*0.53, y: h*0.6, width: w*0.14, height: h*0.2), cornerSize: CGSize(width: 8, height: 8))
        return path
    }
}

struct CalvesPath: Shape {
    var isFront: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addRoundedRect(in: CGRect(x: w*0.33, y: h*0.82, width: w*0.1, height: h*0.1), cornerSize: CGSize(width: 5, height: 5))
        path.addRoundedRect(in: CGRect(x: w*0.57, y: h*0.82, width: w*0.1, height: h*0.1), cornerSize: CGSize(width: 5, height: 5))
        return path
    }
}

struct BackLatsPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w*0.5, y: h*0.15))
        path.addCurve(to: CGPoint(x: w*0.7, y: h*0.28), control1: CGPoint(x: w*0.6, y: h*0.15), control2: CGPoint(x: w*0.7, y: h*0.2))
        path.addLine(to: CGPoint(x: w*0.5, y: h*0.45))
        path.addLine(to: CGPoint(x: w*0.3, y: h*0.28))
        path.addCurve(to: CGPoint(x: w*0.5, y: h*0.15), control1: CGPoint(x: w*0.3, y: h*0.2), control2: CGPoint(x: w*0.4, y: h*0.15))
        return path
    }
}
