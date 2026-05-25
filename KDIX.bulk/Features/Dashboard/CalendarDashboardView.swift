import SwiftUI

// MARK: - 📅 Stats画面 (カレンダー・ダッシュボード形式)
struct CalendarDashboardView: View {
    var logs: [WorkoutLog] = []
    var currentStreak: Int = 12
    var totalVolume: Int = 34500
    var shieldCount: Int = 2
    var onShieldTapped: () -> Void = {}
    var onStartWorkout: () -> Void = {}

    @State private var currentMonth = Date()

    var daysInMonth: [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        return range.compactMap { day -> Date? in
            var d = components
            d.day = day
            return Calendar.current.date(from: d)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. セーフティカー & クイックスタッツ
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL VOLUME").font(.system(size: 10, weight: .black)).foregroundColor(.gray)
                        Text("\(totalVolume) kg").font(.system(size: 24, weight: .black, design: .monospaced)).foregroundColor(.cyan)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("SAFETY CAR").font(.system(size: 10, weight: .black)).foregroundColor(.yellow)
                        HStack(spacing: 8) {
                            Text("\(shieldCount)").font(.system(size: 24, weight: .black, design: .monospaced)).foregroundColor(.yellow)
                            Button(action: onShieldTapped) {
                                SafetyCarIcon(isCharged: shieldCount > 0)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(white: 0.1).opacity(0.8))
                .cornerRadius(20)
                
                // 2. カレンダー
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(currentMonth.formatted(.dateTime.year().month(.wide))).font(.headline).foregroundColor(.white)
                        Spacer()
                        HStack(spacing: 20) {
                            Button { currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)! } label: { Image(systemName: "chevron.left") }
                            Button { currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)! } label: { Image(systemName: "chevron.right") }
                        }
                        .foregroundColor(.cyan)
                    }
                    
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
                    LazyVGrid(columns: columns, spacing: 12) {
                        let firstDayWeekday = Calendar.current.component(.weekday, from: daysInMonth.first!)
                        // 月初の余白
                        ForEach(0..<firstDayWeekday - 1, id: \.self) { _ in Color.clear.frame(height: 32) }
                        
                        ForEach(daysInMonth, id: \.self) { date in
                            let logForDate = logs.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                            let isDone = logForDate != nil
                            let isToday = Calendar.current.isDateInToday(date)
                            let markColor: Color = logForDate?.themeColor.toColor ?? .cyan.opacity(0.3)
                            
                            ZStack {
                                if isDone {
                                    Circle()
                                        .fill(markColor.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(markColor, lineWidth: 1))
                                }
                                
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 14, weight: isDone || isToday ? .bold : .medium, design: .monospaced))
                                    .foregroundColor(isDone ? .white : (isToday ? .cyan : .gray))
                                
                                if isToday && !isDone {
                                    Circle().stroke(Color.cyan, lineWidth: 1).frame(width: 32, height: 32)
                                }
                            }
                            .frame(height: 32)
                        }
                    }
                }
                .padding(20)
                .background(Color(white: 0.1).opacity(0.8))
                .cornerRadius(24)
                
                // 3. ストリーク
                HStack {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("CURRENT STREAK:").font(.system(size: 12, weight: .bold))
                    Text("\(currentStreak) DAYS").font(.system(size: 18, weight: .black, design: .monospaced)).foregroundColor(.orange)
                    Spacer()
                }
                .padding(20)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                
                // 4. シャーシ・ベクター・インジケーター (筋肉ヒートマップ)
                let todayLogs = logs.filter { Calendar.current.isDateInToday($0.date) }
                let fatigueLevels = calculateFatigue(from: todayLogs)
                
                ChassisVectorIndicatorView(fatigueLevels: fatigueLevels)
                    .frame(height: 300)
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // 💥 疲労度計算ロジック
    private func calculateFatigue(from logs: [WorkoutLog]) -> [VectorMusclePart: Double] {
        var levels: [VectorMusclePart: Double] = [:]
        for part in VectorMusclePart.allCases { levels[part] = 0.0 }

        for log in logs {
            for ex in log.exercises {
                // 💥 修正：MuscleDatabase を使用して、150種目以上のデータから正確な部位を特定
                let part = MuscleDatabase.shared.getVectorPart(for: ex.name)
                levels[part] = 1.0 // 今日やった部位はMAX
            }
        }
        return levels
    }
}
