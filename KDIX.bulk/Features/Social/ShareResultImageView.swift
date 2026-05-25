import SwiftUI

enum ShareStyle: String, CaseIterable, Identifiable {
    case classic = "CLASSIC"
    case blueprint = "BLUEPRINT"
    case poster = "POSTER"
    case minimal = "MINIMAL"
    
    var id: String { self.rawValue }
}

struct ShareResultImageView: View {
    let routineName: String
    let driverName: String
    let totalVolume: Int
    let totalTime: String
    let themeColor: Color
    var style: ShareStyle = .classic
    
    var body: some View {
        ZStack {
            switch style {
            case .classic: classicStyle
            case .blueprint: blueprintStyle
            case .poster: posterStyle
            case .minimal: minimalStyle
            }
        }
        .frame(width: 500, height: 500)
        .clipShape(Rectangle())
    }
    
    // 1. Classic (Original upgrade)
    var classicStyle: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "trophy.fill").foregroundColor(themeColor).font(.title)
                Text("MISSION ACCOMPLISHED")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(routineName)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL VOLUME").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                    Text("\(totalVolume) kg").font(.system(size: 32, weight: .heavy, design: .monospaced)).foregroundColor(themeColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIME").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                    Text(totalTime).font(.system(size: 32, weight: .heavy, design: .monospaced)).foregroundColor(.white)
                }
                Spacer()
            }
            .padding(24)
            .background(Color(white: 0.12))
            .cornerRadius(20)
            
            HStack {
                Text("DRIVER: \(driverName)").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                Spacer()
                Text("KDIX.bulk").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(themeColor)
            }
        }
        .padding(40)
        .background(Color(red: 0.05, green: 0.05, blue: 0.05))
    }
    
    // 2. Blueprint (Technical HUD look)
    var blueprintStyle: some View {
        ZStack {
            Color(red: 0.0, green: 0.05, blue: 0.1).ignoresSafeArea()
            
            // Grid
            Path { path in
                for i in 0...20 {
                    let pos = CGFloat(i) * 25
                    path.move(to: CGPoint(x: pos, y: 0))
                    path.addLine(to: CGPoint(x: pos, y: 500))
                    path.move(to: CGPoint(x: 0, y: pos))
                    path.addLine(to: CGPoint(x: 500, y: pos))
                }
            }
            .stroke(Color.cyan.opacity(0.1), lineWidth: 0.5)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("DIAGNOSTIC REPORT // SUCCESS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.bottom, 20)
                
                Text(routineName.uppercased())
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Rectangle().fill(Color.cyan).frame(height: 2)
                
                VStack(alignment: .leading, spacing: 15) {
                    InfoBit(label: "MASS_OUTPUT", value: "\(totalVolume)KG", color: themeColor)
                    InfoBit(label: "DURATION", value: totalTime, color: .white)
                    InfoBit(label: "OPERATOR", value: driverName.uppercased(), color: .gray)
                }
                .padding(.top, 20)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text("KDIX SYSTEM v3.0").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.cyan.opacity(0.5))
                }
            }
            .padding(40)
        }
    }
    
    // 3. Poster (Modern high-contrast)
    var posterStyle: some View {
        ZStack {
            themeColor.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("WORKOUT")
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(.black)
                    .opacity(0.1)
                    .offset(x: -20, y: -20)
                
                Spacer()
                
                Text("\(totalVolume)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                
                Text("KILOGRAMS MOVED")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, -20)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(routineName).font(.title.bold()).foregroundColor(.black)
                        Text(driverName).font(.headline).foregroundColor(.black.opacity(0.7))
                    }
                    Spacer()
                    Text(totalTime).font(.system(size: 40, weight: .black, design: .monospaced)).foregroundColor(.black)
                }
            }
            .padding(40)
        }
    }
    
    // 4. Minimal (Clean & Dark)
    var minimalStyle: some View {
        VStack(alignment: .center, spacing: 30) {
            Spacer()
            
            Circle()
                .stroke(themeColor, lineWidth: 8)
                .frame(width: 150, height: 150)
                .overlay(
                    VStack {
                        Text("\(totalVolume)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                        Text("kg").font(.headline.bold()).foregroundColor(.gray)
                    }
                )
            
            Text(routineName)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                VStack {
                    Text("TIME").font(.caption.bold()).foregroundColor(.gray)
                    Text(totalTime).font(.headline.monospaced())
                }
                VStack {
                    Text("DRIVER").font(.caption.bold()).foregroundColor(.gray)
                    Text(driverName).font(.headline)
                }
            }
            
            Spacer()
            
            Text("KDIX.bulk").font(.system(size: 12, weight: .black, design: .monospaced)).foregroundColor(themeColor)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}

struct InfoBit: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.cyan.opacity(0.6)).frame(width: 120, alignment: .leading)
            Text(value).font(.system(size: 20, weight: .black, design: .monospaced)).foregroundColor(color)
        }
    }
}
