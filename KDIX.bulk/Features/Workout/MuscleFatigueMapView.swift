import SwiftUI

// MARK: - 🧍 筋肉疲労マップ (Hyper-Realistic Anatomical Version)
struct MuscleFatigueMapView: View {
    let logs: [WorkoutLog]
    
    // 将来の拡張性を考慮しつつ、現在は白色ベースで判定結果を受け取る
    func fatigueColor(for muscle: MuscleGroup) -> Color {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let relevantLogs = logs.filter { log in
            let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: log.date), to: today).day ?? 100
            return daysAgo <= 3
        }
        
        let trainedDates = relevantLogs.compactMap { log -> Int? in
            let hasMuscle = log.exercises.contains { ex in
                if let master = allMasterExercises.first(where: { $0.name == ex.name }) {
                    return master.target == muscle
                }
                return false
            }
            if hasMuscle {
                return calendar.dateComponents([.day], from: calendar.startOfDay(for: log.date), to: today).day
            }
            return nil
        }
        
        if trainedDates.contains(0) { return .red } 
        if trainedDates.contains(1) { return .orange } 
        if trainedDates.contains(2) { return .yellow } 
        return .white.opacity(0.15) // 💥 ベースは白（Fresh）
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("MUSCLE STATUS").font(.system(size: 10, weight: .black)).foregroundColor(.gray)
                Spacer()
                HStack(spacing: 12) {
                    LegendItem(color: .red, label: "PEAK")
                    LegendItem(color: .orange, label: "HIGH")
                    LegendItem(color: .yellow, label: "MID")
                    LegendItem(color: .white.opacity(0.15), label: "FRESH")
                }
            }
            
            HStack(spacing: 30) {
                // 正面図
                VStack(spacing: 12) {
                    Text("FRONT VIEW").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.gray.opacity(0.8))
                    ZStack {
                        // 1. 全身の影（奥行き）
                        AnatomicalHumanShape(isFront: true).fill(Color.black.opacity(0.3)).offset(x: 2, y: 2)
                        
                        // 2. ベースのシルエット (白)
                        AnatomicalHumanShape(isFront: true).fill(Color.white.opacity(0.08))
                        
                        // 3. 各筋肉パーツ
                        MusclePart(muscle: .chest, color: fatigueColor(for: .chest), isFront: true)
                        MusclePart(muscle: .core, color: fatigueColor(for: .core), isFront: true)
                        MusclePart(muscle: .shoulders, color: fatigueColor(for: .shoulders), isFront: true)
                        MusclePart(muscle: .arms, color: fatigueColor(for: .arms), isFront: true)
                        MusclePart(muscle: .legs, color: fatigueColor(for: .legs), isFront: true)
                        
                        // 4. リアルな輪郭線
                        AnatomicalHumanShape(isFront: true).stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                    }
                    .frame(width: 150, height: 300)
                }
                
                // 背面図
                VStack(spacing: 12) {
                    Text("REAR VIEW").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.gray.opacity(0.8))
                    ZStack {
                        AnatomicalHumanShape(isFront: false).fill(Color.black.opacity(0.3)).offset(x: 2, y: 2)
                        AnatomicalHumanShape(isFront: false).fill(Color.white.opacity(0.08))
                        
                        MusclePart(muscle: .back, color: fatigueColor(for: .back), isFront: false)
                        MusclePart(muscle: .shoulders, color: fatigueColor(for: .shoulders), isFront: false)
                        MusclePart(muscle: .arms, color: fatigueColor(for: .arms), isFront: false)
                        MusclePart(muscle: .legs, color: fatigueColor(for: .legs), isFront: false)
                        
                        AnatomicalHumanShape(isFront: false).stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                    }
                    .frame(width: 150, height: 300)
                }
            }
        }
        .padding(30)
        .background(Color(white: 0.05).opacity(0.9))
        .cornerRadius(40)
        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - 凡例パーツ
struct LegendItem: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 8, weight: .black)).foregroundColor(.gray)
        }
    }
}

// MARK: - 🎨 筋肉パーツ統合
struct MusclePart: View {
    let muscle: MuscleGroup
    let color: Color
    let isFront: Bool
    
    var body: some View {
        ZStack {
            if isFront {
                switch muscle {
                case .chest: FrontChestShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .core: FrontAbsShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .shoulders: FrontShoulderShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .arms: FrontArmShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .legs: FrontLegShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                default: EmptyView()
                }
            } else {
                switch muscle {
                case .back: BackLatsShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .shoulders: BackShoulderShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .arms: BackArmShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                case .legs: BackLegShape().fill(color).shadow(color: color.opacity(0.5), radius: 5)
                default: EmptyView()
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: color)
    }
}

// MARK: - 📐 アナトミカル・シェイプ定義 (詳細描画)

struct AnatomicalHumanShape: Shape {
    var isFront: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        
        // 💥 超リアルな全身アウトライン
        // 頭・首
        path.addEllipse(in: CGRect(x: w*0.42, y: h*0.02, width: w*0.16, height: h*0.07))
        path.move(to: CGPoint(x: w*0.45, y: h*0.09))
        path.addLine(to: CGPoint(x: w*0.45, y: h*0.11))
        path.addLine(to: CGPoint(x: w*0.55, y: h*0.11))
        path.addLine(to: CGPoint(x: w*0.55, y: h*0.09))
        
        // 肩〜腕〜胴体〜足 (右側)
        path.move(to: CGPoint(x: w*0.5, y: h*0.11))
        path.addCurve(to: CGPoint(x: w*0.75, y: h*0.15), control1: CGPoint(x: w*0.6, y: h*0.11), control2: CGPoint(x: w*0.7, y: h*0.12))
        path.addCurve(to: CGPoint(x: w*0.9, y: h*0.35), control1: CGPoint(x: w*0.85, y: h*0.2), control2: CGPoint(x: w*0.95, y: h*0.25))
        path.addCurve(to: CGPoint(x: w*0.8, y: h*0.45), control1: CGPoint(x: w*0.9, y: h*0.4), control2: CGPoint(x: w*0.85, y: h*0.45))
        path.addCurve(to: CGPoint(x: w*0.65, y: h*0.25), control1: CGPoint(x: w*0.75, y: h*0.4), control2: CGPoint(x: w*0.7, y: h*0.35))
        path.addCurve(to: CGPoint(x: w*0.62, y: h*0.55), control1: CGPoint(x: w*0.65, y: h*0.4), control2: CGPoint(x: w*0.65, y: h*0.5))
        path.addCurve(to: CGPoint(x: w*0.72, y: h*0.96), control1: CGPoint(x: w*0.6, y: h*0.7), control2: CGPoint(x: w*0.75, y: h*0.85))
        path.addLine(to: CGPoint(x: w*0.56, y: h*0.96))
        path.addCurve(to: CGPoint(x: w*0.5, y: h*0.65), control1: CGPoint(x: w*0.55, y: h*0.85), control2: CGPoint(x: w*0.52, y: h*0.75))
        
        // 左側 (対称)
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

// 💥 以下、各筋肉部位の有機的な描画ロジック

struct FrontChestShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 大胸筋 (左右)
        for side in [-1.0, 1.0] {
            let cx = w*0.5 + CGFloat(side)*w*0.1
            path.addEllipse(in: CGRect(x: cx - w*0.08, y: h*0.15, width: w*0.16, height: h*0.09))
        }
        return path
    }
}

struct FrontAbsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 腹直筋 (6パック)
        for row in 0..<3 {
            for col in [-1.0, 1.0] {
                let cx = w*0.5 + CGFloat(col)*w*0.035
                path.addRoundedRect(in: CGRect(x: cx - w*0.03, y: h*(0.28 + Double(row)*0.04), width: w*0.06, height: h*0.03), cornerSize: CGSize(width: 2, height: 2))
            }
        }
        return path
    }
}

struct BackLatsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 広背筋 (V字)
        path.move(to: CGPoint(x: w*0.5, y: h*0.15))
        path.addCurve(to: CGPoint(x: w*0.7, y: h*0.28), control1: CGPoint(x: w*0.6, y: h*0.15), control2: CGPoint(x: w*0.7, y: h*0.2))
        path.addLine(to: CGPoint(x: w*0.5, y: h*0.45))
        path.addLine(to: CGPoint(x: w*0.3, y: h*0.28))
        path.addCurve(to: CGPoint(x: w*0.5, y: h*0.15), control1: CGPoint(x: w*0.3, y: h*0.2), control2: CGPoint(x: w*0.4, y: h*0.15))
        return path
    }
}

struct FrontShoulderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w*0.22, y: h*0.13, width: w*0.12, height: h*0.08))
        path.addEllipse(in: CGRect(x: w*0.66, y: h*0.13, width: w*0.12, height: h*0.08))
        return path
    }
}

struct BackShoulderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.addEllipse(in: CGRect(x: w*0.22, y: h*0.13, width: w*0.12, height: h*0.08))
        path.addEllipse(in: CGRect(x: w*0.66, y: h*0.13, width: w*0.12, height: h*0.08))
        return path
    }
}

struct FrontArmShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 二頭筋・前腕
        path.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.22, width: w*0.08, height: h*0.12), cornerSize: CGSize(width: 5, height: 5))
        path.addRoundedRect(in: CGRect(x: w*0.74, y: h*0.22, width: w*0.08, height: h*0.12), cornerSize: CGSize(width: 5, height: 5))
        path.addRoundedRect(in: CGRect(x: w*0.13, y: h*0.34, width: w*0.07, height: h*0.1), cornerSize: CGSize(width: 3, height: 3))
        path.addRoundedRect(in: CGRect(x: w*0.8, y: h*0.34, width: w*0.07, height: h*0.1), cornerSize: CGSize(width: 3, height: 3))
        return path
    }
}

struct BackArmShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 三頭筋
        path.addRoundedRect(in: CGRect(x: w*0.18, y: h*0.21, width: w*0.09, height: h*0.15), cornerSize: CGSize(width: 6, height: 6))
        path.addRoundedRect(in: CGRect(x: w*0.73, y: h*0.21, width: w*0.09, height: h*0.15), cornerSize: CGSize(width: 6, height: 6))
        return path
    }
}

struct FrontLegShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // 大腿四頭筋
        path.addRoundedRect(in: CGRect(x: w*0.32, y: h*0.58, width: w*0.14, height: h*0.22), cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: CGRect(x: w*0.54, y: h*0.58, width: w*0.14, height: h*0.22), cornerSize: CGSize(width: 10, height: 10))
        // 下腿
        path.addRoundedRect(in: CGRect(x: w*0.33, y: h*0.82, width: w*0.09, height: h*0.1), cornerSize: CGSize(width: 4, height: 4))
        path.addRoundedRect(in: CGRect(x: w*0.58, y: h*0.82, width: w*0.09, height: h*0.1), cornerSize: CGSize(width: 4, height: 4))
        return path
    }
}

struct BackLegShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        // ハムストリング・ふくらはぎ
        path.addRoundedRect(in: CGRect(x: w*0.32, y: h*0.58, width: w*0.14, height: h*0.22), cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: CGRect(x: w*0.54, y: h*0.58, width: w*0.14, height: h*0.22), cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: CGRect(x: w*0.31, y: h*0.81, width: w*0.1, height: h*0.1), cornerSize: CGSize(width: 5, height: 5))
        path.addRoundedRect(in: CGRect(x: w*0.59, y: h*0.81, width: w*0.1, height: h*0.1), cornerSize: CGSize(width: 5, height: 5))
        return path
    }
}
