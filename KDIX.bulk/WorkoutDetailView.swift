import SwiftUI
import SwiftData
import Combine

struct SetRecord: Equatable, Codable {
    var weight: Double
    var reps: Int
}

struct WorkoutDraft: Codable {
    var secondsElapsed: Int
    var completedSets: [String: [Int: SetRecord]]
    var lastSavedDate: Date
}

import SwiftUI
import SwiftData

// MARK: - ⏱️ 独立型タイマービュー（画面全体のフリーズ・クラッシュを完全阻止！）
struct IsolatedTimerView: View {
    let startTime: Date
    let initialSeconds: Int
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let total = initialSeconds + Int(now.timeIntervalSince(startTime))
        Text(formatTime(total))
            .font(.custom("AvenirNext-Heavy", size: 32))
            .foregroundColor(.white)
            .onReceive(timer) { time in
                now = time // ここだけが毎秒更新されるため、他の画面は一切干渉を受けない！
            }
    }
    func formatTime(_ s: Int) -> String { String(format: "%02d:%02d", s / 60, s % 60) }
}


// MARK: - トレーニング計測画面 (WorkoutDetailView)
struct WorkoutDetailView: View {
    let routine: WorkoutRoutine
    @Binding var isRootActive: Bool
    @Query(sort: \WorkoutLog.date, order: .reverse) private var pastLogs: [WorkoutLog]
    @Environment(\.scenePhase) var scenePhase
    
    // 💥 修正：タイマーを回す処理を全削除し、時間計算用の変数のみに変更
    @State private var sessionStartTime: Date = Date()
    @State private var initialSecondsElapsed: Int = 0
    
    @State private var completedSets: [String: [Int: SetRecord]] = [:]
    
    @State private var showResult = false
    @State private var showInputCard = false
    @State private var editingWeight: Double = 60.0
    @State private var editingReps: Int = 10
    @State private var currentEditingExName: String = ""
    @State private var currentEditingSetNum: Int = 0
    
    @State private var showExerciseSheet = false
    @State private var newExercises: [DraftExercise] = []

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.06).ignoresSafeArea()
            
            mainWorkoutContentView
            
            if showInputCard {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring()) { showInputCard = false } }
                    inputCardView
                }
                .zIndex(2)
            }
            
            if showResult {
                let finalSeconds = initialSecondsElapsed + Int(Date().timeIntervalSince(sessionStartTime))
                ResultView(
                    routine: routine,
                    completedSets: completedSets,
                    secondsElapsed: finalSeconds,
                    calculateTotalVolume: calculateTotalVolume(),
                    isRootActive: $isRootActive
                )
                .zIndex(3)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !showResult && !showInputCard {
                    Button {
                        withAnimation { showResult = true }
                    } label: {
                        Text("FINISH")
                            .font(.custom("AvenirNext-Bold", size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        // 💥 .onReceive(timer) はもうここには存在しません！
        .onAppear { loadDraft() }
        .onChange(of: scenePhase) { oldPhase, newPhase in handleScenePhase(newPhase) }
        .sheet(isPresented: $showExerciseSheet) {
            ExerciseSelectionView(selectedExercises: $newExercises)
                .onDisappear { addSelectedExercises() }
        }
    }
    
    // MARK: - 🧩 UIパーツ分割
    private var mainWorkoutContentView: some View {
            VStack(spacing: 0) {
                timerHeaderView
                ScrollView {
                    exerciseListView
                }
                // 💥 追加：スクロール時に中のカードがピタッと止まるようにする！
                .scrollTargetBehavior(.viewAligned)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .zIndex(1)
        }
    
    private var timerHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT MISSION").font(.custom("AvenirNext-Bold", size: 10)).foregroundColor(.gray)
                Text(routine.title).font(.system(size: 20, weight: .black)).foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: -2) {
                Text("ELAPSED TIME").font(.custom("AvenirNext-Bold", size: 10)).foregroundColor(.gray)
                // 💥 ここで独立したタイマービューを呼び出す！
                IsolatedTimerView(startTime: sessionStartTime, initialSeconds: initialSecondsElapsed)
            }
        }
        .padding(20)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
        .padding(.horizontal, 20).padding(.top, 10)
    }
    
    private var exerciseListView: some View {
        LazyVStack(spacing: 16) {
            if routine.exercises.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill").font(.largeTitle).foregroundColor(.secondary.opacity(0.5))
                    Text("種目がありません").font(.subheadline).foregroundColor(.secondary)
                }.padding(.top, 40)
            } else {
                let safeExercises = Array(routine.exercises).sorted(by: { $0.orderIndex < $1.orderIndex })
                
                ForEach(safeExercises) { ex in
                    WorkoutCardView(
                        ex: ex,
                        isExerciseCompleted: isExerciseCompleted(ex: ex),
                        completedSets: completedSets[ex.name] ?? [:],
                        themeColor: routine.themeColor.toColor
                    ) { (setNum: Int) in
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        startEdit(ex: ex, setNum: setNum)
                    }
                }
            }
            
            Button {
                showExerciseSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundColor(.white).font(.title3)
                    Text("ADD EXERCISE").font(.custom("AvenirNext-Heavy", size: 16)).foregroundColor(.white)
                }
                .padding().frame(maxWidth: .infinity)
                .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 5)
            }
            .padding(.top, 8)
        }
        .scrollTargetLayout()
        .padding().padding(.bottom, 100)
    }
    
    private var inputCardView: some View {
        let themeColor = routine.themeColor.toColor
        
        return VStack {
            Spacer()
            VStack(spacing: 20) {
                HStack {
                    Text("\(currentEditingExName)").font(.headline).foregroundColor(.white)
                    Spacer()
                    Text("SET \(currentEditingSetNum)").font(.system(.title3, design: .rounded).weight(.black)).foregroundColor(themeColor)
                }
                
                if let prevRecord = getPreviousRecord(exName: currentEditingExName, setNum: currentEditingSetNum) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("前回: \(Int(prevRecord.weight))kg × \(prevRecord.reps)回")
                    }
                    .font(.subheadline.bold()).foregroundColor(.orange)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.orange.opacity(0.15)).clipShape(Capsule())
                } else if let targetEx = routine.exercises.first(where: { $0.name == currentEditingExName }) {
                    HStack {
                        Image(systemName: "target")
                        Text("目標: \(Int(targetEx.baseWeight))kg × \(targetEx.baseReps)回")
                    }
                    .font(.subheadline.bold()).foregroundColor(themeColor)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(themeColor.opacity(0.15)).clipShape(Capsule())
                }
                
                HStack {
                    VStack {
                        Text("Weight").font(.caption.weight(.black)).foregroundColor(.gray)
                        Picker("Weight", selection: $editingWeight) {
                            ForEach(0...600, id: \.self) { i in
                                let w = Double(i) * 0.5
                                Text(String(format: "%.1f", w)).tag(w)
                            }
                        }
                        .pickerStyle(.wheel).frame(width: 100, height: 100)
                    }
                    VStack {
                        Text("Reps").font(.caption.weight(.black)).foregroundColor(.gray)
                        Picker("Reps", selection: $editingReps) {
                            ForEach(1...50, id: \.self) { r in Text("\(r)").tag(r) }
                        }
                        .pickerStyle(.wheel).frame(width: 100, height: 100)
                    }
                }
                .environment(\.colorScheme, .dark)
                
                Button {
                    saveSetRecord()
                    withAnimation(.spring()) { showInputCard = false }
                } label: {
                    Text("REGISTER").font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(themeColor).cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(themeColor.opacity(0.3), lineWidth: 1))
            .shadow(color: themeColor.opacity(0.2), radius: 20, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - メソッド群
    
    private func handleScenePhase(_ newPhase: ScenePhase) {
        if newPhase == .background {
            saveDraft()
        }
    }
    
    private func addSelectedExercises() {
        for draft in newExercises {
            let ex = RoutineExercise(
                name: draft.master.name, target: draft.master.target.rawValue, equipment: draft.master.equipment.rawValue,
                baseWeight: draft.weight, baseReps: draft.reps, sets: draft.sets
            )
            routine.exercises.append(ex)
        }
        newExercises.removeAll()
    }
    
    func getPreviousRecord(exName: String, setNum: Int) -> SetRecordEntity? {
        for log in pastLogs {
            if let pastEx = log.exercises.first(where: { $0.name == exName }) {
                if let pastSet = pastEx.sets.first(where: { $0.setNumber == setNum }) { return pastSet }
            }
        }
        return nil
    }

    func startEdit(ex: RoutineExercise, setNum: Int) {
        currentEditingExName = ex.name
        currentEditingSetNum = setNum
        
        if let currentSessionSets = completedSets[ex.name], let lastSetRecord = currentSessionSets[setNum - 1] {
            editingWeight = lastSetRecord.weight
            editingReps = lastSetRecord.reps
        } else if let prevHistoryRecord = getPreviousRecord(exName: ex.name, setNum: setNum) {
            editingWeight = prevHistoryRecord.weight
            editingReps = prevHistoryRecord.reps
        } else {
            editingWeight = ex.baseWeight
            editingReps = ex.baseReps
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            showInputCard = true
        }
    }
    
    func saveSetRecord() {
        if completedSets[currentEditingExName] == nil { completedSets[currentEditingExName] = [:] }
        completedSets[currentEditingExName]?[currentEditingSetNum] = SetRecord(weight: editingWeight, reps: editingReps)
        saveDraft()
    }
    
    func saveDraft() {
        let totalSecs = initialSecondsElapsed + Int(Date().timeIntervalSince(sessionStartTime))
        let draft = WorkoutDraft(secondsElapsed: totalSecs, completedSets: completedSets, lastSavedDate: Date())
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: "draft_\(routine.id.uuidString)")
            UserDefaults.standard.set(routine.id.uuidString, forKey: "activeWorkoutId")
        }
    }

    func loadDraft() {
        if let data = UserDefaults.standard.data(forKey: "draft_\(routine.id.uuidString)"),
           let draft = try? JSONDecoder().decode(WorkoutDraft.self, from: data) {
            self.completedSets = draft.completedSets
            let timeAway = Date().timeIntervalSince(draft.lastSavedDate)
            if timeAway < 43200 {
                self.initialSecondsElapsed = draft.secondsElapsed + Int(timeAway)
            } else {
                self.initialSecondsElapsed = draft.secondsElapsed
            }
        }
        self.sessionStartTime = Date() // タイマー基準点をセット
    }
    
    func isExerciseCompleted(ex: RoutineExercise) -> Bool {
        guard let sets = completedSets[ex.name] else { return false }
        for setNum in 1...ex.sets { if sets[setNum] == nil { return false } }
        return true
    }
    
    func calculateTotalVolume() -> Double {
        var total: Double = 0
        for ex in routine.exercises {
            if let sets = completedSets[ex.name] {
                for setNum in 1...ex.sets {
                    if let record = sets[setNum] { total += record.weight * Double(record.reps) }
                }
            }
        }
        return total
    }
}

// MARK: - リザルト画面 (ResultView)
struct ResultView: View {
    @Environment(\.modelContext) var modelContext
    let routine: WorkoutRoutine
    let completedSets: [String: [Int: SetRecord]]
    let secondsElapsed: Int
    let calculateTotalVolume: Double
    @Binding var isRootActive: Bool
    
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.5).ignoresSafeArea() // 背景を暗く
            
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill").font(.system(size: 60)).foregroundColor(.yellow).shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 5)
                        Text("MISSION COMPLETE").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    VStack(spacing: 0) {
                        ResultRow(icon: "clock.fill", title: "Total Time", value: formatTime(secondsElapsed), color: .white)
                        Divider().padding(.leading, 40).background(Color.white.opacity(0.1))
                        ResultRow(icon: "dumbbell.fill", title: "Total Volume", value: "\(Int(calculateTotalVolume)) kg", color: routine.themeColor.toColor)
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).padding(.horizontal, 20)
                    
                    Button {
                        let newLog = WorkoutLog(dayTitle: routine.title, totalSeconds: secondsElapsed, themeColor: routine.themeColor)
                        for ex in routine.exercises {
                            if let sets = completedSets[ex.name] {
                                let exLog = ExerciseLog(name: ex.name)
                                for setNum in 1...ex.sets {
                                    if let record = sets[setNum] {
                                        let setEntity = SetRecordEntity(setNumber: setNum, weight: record.weight, reps: record.reps)
                                        exLog.sets.append(setEntity)
                                    }
                                }
                                if !exLog.sets.isEmpty { newLog.exercises.append(exLog) }
                            }
                        }
                        modelContext.insert(newLog)
                        UserDefaults.standard.removeObject(forKey: "draft_\(routine.id.uuidString)")
                        UserDefaults.standard.removeObject(forKey: "activeWorkoutId")
                        isRootActive = false
                    } label: {
                        Text("Return to Garage").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(routine.themeColor.toColor).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 40)
            }
        }
    }
    func formatTime(_ s: Int) -> String { String(format: "%02d:%02d", s / 60, s % 60) }
}

// MARK: - 新規追加：レスト時間ボタンのデザイン
struct RestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundColor(.blue)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(Color.blue.opacity(0.15))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}



struct ResultRow: View {
    let icon: String; let title: String; let value: String; let color: Color
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color).frame(width: 30)
            Text(title).font(.body)
            Spacer()
            Text(value).font(.system(.body, design: .rounded)).foregroundColor(.secondary)
        }.padding(.vertical, 16).padding(.horizontal, 20)
    }
}

// MARK: - 種目カード (WorkoutCardView - ガレージ仕様)
struct WorkoutCardView: View {
    @Bindable var ex: RoutineExercise
    let isExerciseCompleted: Bool
    let completedSets: [Int: SetRecord]
    let themeColor: Color
    let onSetTapped: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー部分
            HStack(alignment: .top) {
                NavigationLink(destination: ExerciseHistoryView(exerciseName: ex.name)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            // 💥 サイバーな水色を撤廃し、ソリッドな白に変更
                            Text(ex.name).font(.system(size: 22, weight: .black)).foregroundColor(.white)
                            Image(systemName: "bolt.horizontal.fill").font(.caption2).foregroundColor(themeColor)
                        }
                        HStack {
                            Text(ex.target).font(.custom("AvenirNext-Medium", size: 14)).foregroundColor(.gray)
                            if ex.equipment != "なし" && ex.equipment != "その他" { Text("・ \(ex.equipment)").font(.custom("AvenirNext-Medium", size: 14)).foregroundColor(.gray) }
                        }
                    }
                }.buttonStyle(.plain)
                
                Spacer(minLength: 10)
                
                // 予定セット数の増減ボタン
                HStack(spacing: 8) {
                    if ex.sets > 1 {
                        Button { withAnimation { ex.sets -= 1 } } label: { Image(systemName: "minus.square.fill").font(.title2).foregroundColor(.gray) }
                    }
                    // 💥 バッジを鉄プレート風のデザインに
                    Text("\(ex.sets) SETS")
                        .font(.custom("AvenirNext-Bold", size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(white: 0.8))
                        .cornerRadius(4)
                    if ex.sets < 6 {
                        Button { withAnimation { ex.sets += 1 } } label: { Image(systemName: "plus.square.fill").font(.title2).foregroundColor(.gray) }
                    }
                }
            }
            
            // シフトUI呼び出し
            VStack {
                MissionShiftView(
                    totalSets: ex.sets,
                    completedSetsCount: completedSets.keys.count,
                    themeColor: themeColor, // 💥 テーマカラーを渡す
                    onShiftUp: { (setNum: Int) in onSetTapped(setNum) },
                    onShiftDown: { (setNum: Int) in onSetTapped(setNum) }
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .padding(20)
        // 💥 カードの背景色をより暗いアスファルト・カーボン色に
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.6), radius: 15, x: 0, y: 10)
        .overlay(
            VStack {
                if isExerciseCompleted {
                    HStack {
                        Spacer()
                        // 💥 完了シールを無骨な色合いに変更
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(themeColor)
                            .font(.system(size: 32))
                            .shadow(color: themeColor.opacity(0.3), radius: 5)
                            .padding(10)
                    }
                    Spacer()
                }
            }
        )
    }
}

// MARK: - 種目の詳細履歴画面 (ExerciseHistoryView)
struct ExerciseHistoryView: View {
    let exerciseName: String
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allLogs: [WorkoutLog]
    
    var exerciseLogs: [(Date, ExerciseLog)] {
        allLogs.compactMap { log in
            if let exLog = log.exercises.first(where: { $0.name == exerciseName }) { return (log.date, exLog) }
            return nil
        }
    }

    var body: some View {
        List {
            Section("過去の記録") {
                if exerciseLogs.isEmpty {
                    Text("まだ記録がありません").foregroundColor(.secondary)
                } else {
                    ForEach(exerciseLogs, id: \.0) { date, log in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(date, style: .date).font(.caption.bold()).foregroundColor(.blue)
                            ForEach(log.sets) { set in
                                HStack {
                                    Text("\(set.setNumber)セット目")
                                    Spacer()
                                    Text("\(Int(set.weight))kg × \(set.reps)回").bold()
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle(exerciseName)
    }
}

// MARK: - ⚙️ ワイスピ仕様：リアル・ミッションシフトUI (完全解決版)
struct MissionShiftView: View {
    let totalSets: Int
    let completedSetsCount: Int
    let themeColor: Color
    
    let onShiftUp: (Int) -> Void
    let onShiftDown: (Int) -> Void
    
    @State private var currentGear: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var lastHapticOffset: CGSize = .zero
    
    let colW: CGFloat = 55
    let rowH: CGFloat = 50
    let gateThickness: CGFloat = 16
    let mechanicalSpring = Animation.interactiveSpring(response: 0.15, dampingFraction: 0.8, blendDuration: 0)
    
    func position(for gear: Int) -> CGSize {
        switch gear {
        case 1: return CGSize(width: -colW, height: -rowH)
        case 2: return CGSize(width: -colW, height: rowH)
        case 3: return CGSize(width: 0, height: -rowH)
        case 4: return CGSize(width: 0, height: rowH)
        case 5: return CGSize(width: colW, height: -rowH)
        case 6: return CGSize(width: colW, height: rowH)
        default: return .zero
        }
    }
    
    func clampToHPattern(target: CGSize) -> CGSize {
        let pN = CGSize(width: min(max(target.width, -colW), colW), height: 0)
        let p12 = CGSize(width: -colW, height: min(max(target.height, -rowH), rowH))
        let p34 = CGSize(width: 0, height: min(max(target.height, -rowH), rowH))
        let p56 = CGSize(width: colW, height: min(max(target.height, -rowH), rowH))
        
        let points = [pN, p12, p34, p56]
        var closestPoint = target
        var minDistance: CGFloat = .infinity
        for p in points {
            let d = hypot(target.width - p.width, target.height - p.height)
            if d < minDistance {
                minDistance = d
                closestPoint = p
            }
        }
        return closestPoint
    }
    
    var body: some View {
        ZStack {
            Circle().fill(Color(white: 0.05)).frame(width: 250, height: 250).shadow(color: .black.opacity(0.8), radius: 10, y: 5)
            
            Circle().fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.65), Color(white: 0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 220, height: 220)
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.8), radius: 4, y: 2)
                .mask(ZStack { Rectangle().fill(Color.white); shiftGateHoles }.compositingGroup())
            
            bolts
            gearNumbers
            shiftKnob
        }
        .frame(height: 280)
        .onAppear { syncState() }
        .onChange(of: completedSetsCount) { _, _ in syncState() }
    }
    
    private var shiftGateHoles: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.black).frame(width: colW * 2 + gateThickness + 4, height: gateThickness).blendMode(.destinationOut)
            RoundedRectangle(cornerRadius: 6).fill(Color.black).frame(width: gateThickness, height: rowH * 2 + gateThickness).offset(x: -colW).blendMode(.destinationOut)
            RoundedRectangle(cornerRadius: 6).fill(Color.black).frame(width: gateThickness, height: rowH * 2 + gateThickness).offset(x: 0).blendMode(.destinationOut)
            RoundedRectangle(cornerRadius: 6).fill(Color.black).frame(width: gateThickness, height: rowH * 2 + gateThickness).offset(x: colW).blendMode(.destinationOut)
        }
    }
    
    private var bolts: some View {
        let radius: CGFloat = 95
        return ForEach(0..<6, id: \.self) { i in
            let angle = Angle.degrees(Double(i) * 60.0 + 30.0)
            let x = cos(angle.radians) * radius; let y = sin(angle.radians) * radius
            Circle().fill(LinearGradient(colors: [Color(white: 0.9), Color(white: 0.4)], startPoint: .top, endPoint: .bottom)).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1)).overlay(Image(systemName: "hexagon.fill").font(.system(size: 8)).foregroundColor(Color.black.opacity(0.8))).offset(x: x, y: y)
        }
    }
    
    private var gearNumbers: some View {
        ForEach(1...6, id: \.self) { gear in
            let pos = position(for: gear); let isTopRow = gear % 2 != 0
            Text("\(gear)").font(.custom("AvenirNext-Bold", size: 14)).foregroundColor(Color(white: 0.35)).shadow(color: .white.opacity(0.8), radius: 0.5, x: 0, y: 1).offset(x: pos.width, y: pos.height + (isTopRow ? -18 : 18))
        }
    }
    
    private var shiftKnob: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [Color(white: 0.7), Color(white: 0.3), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)).frame(width: 14, height: 40).offset(y: 18).shadow(color: .black.opacity(0.9), radius: 3, y: 5)
            Circle().fill(RadialGradient(gradient: Gradient(colors: [.white, Color(white: 0.6), Color(white: 0.3), .black]), center: .topLeading, startRadius: 5, endRadius: 35)).frame(width: 64, height: 64).shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 15).overlay(Ellipse().fill(LinearGradient(colors: [.white.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)).frame(width: 40, height: 20).offset(y: -15).rotationEffect(.degrees(-15)))
            
            if currentGear >= totalSets && totalSets > 0 {
                Text("DONE").font(.custom("AvenirNext-Heavy", size: 16)).foregroundColor(themeColor).shadow(color: themeColor.opacity(0.5), radius: 3)
            } else if isDragging {
                Text(currentGear == 0 ? "N" : "\(currentGear)").font(.custom("AvenirNext-Heavy", size: 24)).foregroundColor(themeColor).shadow(color: themeColor.opacity(0.5), radius: 3)
            }
        }
        .offset(dragOffset)
        .gesture(shiftGesture)
    }
    
    private var shiftGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                let rawOffset = CGSize(width: baseOffset.width + value.translation.width, height: baseOffset.height + value.translation.height)
                let clampedOffset = clampToHPattern(target: rawOffset)
                
                let hapticDist = hypot(clampedOffset.width - lastHapticOffset.width, clampedOffset.height - lastHapticOffset.height)
                if hapticDist > 15 {
                    // 💥 安全なマネージャー経由で呼び出す！
                    HardwareManager.shared.playSelection()
                    lastHapticOffset = clampedOffset
                }
                
                if abs(clampedOffset.height) < 5 && abs(dragOffset.height) >= 5 {
                    HardwareManager.shared.playMedium()
                }
                
                dragOffset = clampedOffset
            }
            .onEnded { value in
                isDragging = false
                let rawOffset = CGSize(width: baseOffset.width + value.translation.width, height: baseOffset.height + value.translation.height)
                let finalOffset = clampToHPattern(target: rawOffset)
                
                let targetUp = currentGear + 1; let targetDown = currentGear - 1
                let posUp = position(for: targetUp); let posDown = position(for: targetDown)
                let distUp = hypot(finalOffset.width - posUp.width, finalOffset.height - posUp.height)
                let distDown = hypot(finalOffset.width - posDown.width, finalOffset.height - posDown.height)
                let snapRadius: CGFloat = 35
                
                if distUp < snapRadius && targetUp <= totalSets && targetUp <= 6 {
                    HardwareManager.shared.playHeavy()
                    ShiftSoundManager.shared.playShiftUpSequence(gear: targetUp)
                    
                    currentGear = targetUp; baseOffset = posUp
                    withAnimation(mechanicalSpring) { dragOffset = posUp }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onShiftUp(targetUp) }
                } else if distDown < snapRadius && targetDown >= 1 {
                    HardwareManager.shared.playHeavy()
                    ShiftSoundManager.shared.playShiftDownSequence(gear: targetDown)
                    
                    currentGear = targetDown; baseOffset = posDown
                    withAnimation(mechanicalSpring) { dragOffset = posDown }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onShiftDown(targetDown) }
                } else {
                    HardwareManager.shared.playRigid()
                    withAnimation(mechanicalSpring) { dragOffset = baseOffset }
                }
            }
    }
    
    func syncState() {
        currentGear = min(completedSetsCount, totalSets)
        baseOffset = position(for: currentGear)
        dragOffset = baseOffset
        lastHapticOffset = baseOffset
    }
}
