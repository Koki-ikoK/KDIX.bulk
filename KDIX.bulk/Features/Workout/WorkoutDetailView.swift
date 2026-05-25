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

// MARK: - ⏱️ 独立型タイマービュー
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
                now = time
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
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var sessionManager = WorkoutSessionManager.shared
    
    @State private var showResult = false
    @State private var showInputCard = false
    @State private var editingWeight: Double = 60.0
    @State private var editingReps: Int = 10
    @State private var currentEditingExName: String = ""
    @State private var currentEditingSetNum: Int = 0
    
    @State private var showExerciseSheet = false
    @State private var newExercises: [DraftExercise] = []
    
    @State private var showPitRadio = false
    @State private var pitRecommendation: PitRadioEngine.Recommendation? = nil
    @State private var typingMessage: String = "" // 💥 タイピング効果用

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
                ResultView(
                    routine: routine,
                    activeExercises: sessionManager.activeExercises,
                    completedSets: sessionManager.completedSets,
                    secondsElapsed: sessionManager.initialSecondsElapsed + Int(Date().timeIntervalSince(sessionManager.sessionStartTime)),
                    calculateTotalVolume: sessionManager.calculateTotalVolume(),
                    isRootActive: $isRootActive
                )
                .zIndex(3)
            }
            
            if showPitRadio, let rec = pitRecommendation {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring()) { showPitRadio = false } }
                    pitRadioView(rec: rec)
                }
                .zIndex(4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !showResult && !showInputCard {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                            Text("MINIMIZE")
                        }
                        .font(.custom("AvenirNext-Bold", size: 12))
                        .foregroundColor(.gray)
                    }
                }
            }
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
        .onAppear { 
            sessionManager.startSession(with: routine) 
            let driverName = UserDefaults.standard.string(forKey: "driverName") ?? "GUEST"
            FirebaseManager.shared.updateLiveTelemetry(ownerName: driverName, routineTitle: routine.title, exercise: routine.exercises.first?.name ?? "READY", set: 1)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in 
            if newPhase == .background { sessionManager.saveDraft() }
        }
        .sheet(isPresented: $showExerciseSheet) {
            ExerciseSelectionView(selectedExercises: $newExercises, activeNeonColor: routine.themeColor.toColor)
                .onDisappear { addSelectedExercises() }
        }
    }
    
    private var mainWorkoutContentView: some View {
        VStack(spacing: 0) {
            timerHeaderView
            ScrollView {
                exerciseListView
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .zIndex(1)
    }
    
    private var exerciseListView: some View {
        LazyVStack(spacing: 16) {
            if sessionManager.activeExercises.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill").font(.largeTitle).foregroundColor(.secondary.opacity(0.5))
                    Text("種目がありません").font(.subheadline).foregroundColor(.secondary)
                    
                    Button {
                        showExerciseSheet = true
                    } label: {
                        Text("ADD FIRST EXERCISE")
                            .font(.custom("AvenirNext-Heavy", size: 14))
                            .padding()
                            .background(routine.themeColor.toColor.opacity(0.2))
                            .cornerRadius(12)
                    }
                }.padding(.top, 40)
            } else {
                let safeExercises = sessionManager.activeExercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                
                ForEach(Array(safeExercises.enumerated()), id: \.element.id) { index, ex in
                    WorkoutCardView(
                        ex: ex,
                        isExerciseCompleted: isExerciseCompleted(ex: ex),
                        completedSets: sessionManager.completedSets[ex.name] ?? [:],
                        themeColor: routine.themeColor.toColor,
                        onMoveUp: index > 0 ? {
                            withAnimation(.spring()) { sessionManager.moveExercise(from: index, to: index - 1) }
                        } : nil,
                        onMoveDown: index < safeExercises.count - 1 ? {
                            withAnimation(.spring()) { sessionManager.moveExercise(from: index, to: index + 1) }
                        } : nil
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
    
    private var timerHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT MISSION").font(.custom("AvenirNext-Bold", size: 10)).foregroundColor(.gray)
                Text(routine.title).font(.system(size: 20, weight: .black)).foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: -2) {
                Text("ELAPSED TIME").font(.custom("AvenirNext-Bold", size: 10)).foregroundColor(.gray)
                IsolatedTimerView(startTime: sessionManager.sessionStartTime, initialSeconds: sessionManager.initialSecondsElapsed)
            }
        }
        .padding(20)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
        .padding(.horizontal, 20).padding(.top, 10)
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
                } else if let targetEx = sessionManager.activeExercises.first(where: { $0.name == currentEditingExName }) {
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
                    sessionManager.saveSet(exName: currentEditingExName, setNum: currentEditingSetNum, weight: editingWeight, reps: editingReps)
                    withAnimation(.spring()) { showInputCard = false }
                    
                    if let targetEx = sessionManager.activeExercises.first(where: { $0.name == currentEditingExName }),
                       currentEditingSetNum < targetEx.sets {
                        
                        // 📡 PIT RADIO 解析の実行
                        let telemetry = SetTelemetry(
                            weight: editingWeight,
                            reps: editingReps,
                            targetReps: targetEx.baseReps
                        )
                        let rec = PitRadioEngine.shared.analyze(telemetry: telemetry, exerciseName: currentEditingExName)
                        
                        pitRecommendation = rec
                        typingMessage = "" 
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let haptic = UIImpactFeedbackGenerator(style: .rigid)
                            haptic.impactOccurred()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showPitRadio = true
                            }
                            startTypingEffect(for: rec.message) 
                        }
                    }
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

    private func startTypingEffect(for message: String) {
        typingMessage = ""
        let characters = Array(message)
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if index < characters.count {
                typingMessage.append(characters[index])
                index += 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func addSelectedExercises() {
        let currentCount = sessionManager.activeExercises.count
        for (index, draft) in newExercises.enumerated() {
            let ex = RoutineExercise(
                name: draft.master.name, target: draft.master.target.rawValue, equipment: draft.master.equipment.rawValue,
                baseWeight: draft.weight, baseReps: draft.reps, sets: draft.sets,
                orderIndex: currentCount + index
            )
            sessionManager.activeExercises.append(ex)
        }
        newExercises.removeAll()
        sessionManager.saveDraft()
    }
    
    func getPreviousRecord(exName: String, setNum: Int) -> SetRecordEntity? {
        for log in pastLogs {
            if let pastEx = log.exercises.first(where: { $0.name == exName }) {
                if let pastSet = pastEx.sets.first(where: { $0.setNumber == setNum }) { return pastSet }
            }
        }
        return nil
    }
    
    func getRecommendation(for exName: String, setNum: Int) -> AutoregulationEngine.Recommendation? {
        guard setNum > 1,
              let targetEx = sessionManager.activeExercises.first(where: { $0.name == exName }),
              let prevRecord = sessionManager.completedSets[exName]?[setNum - 1] else {
            return nil
        }
        return AutoregulationEngine.shared.recommendNextSet(
            targetMin: max(1, targetEx.baseReps - 2),
            targetMax: targetEx.baseReps + 2,
            currentWeight: prevRecord.weight,
            actualReps: prevRecord.reps,
            rir: 0.0
        )
    }

    func startEdit(ex: RoutineExercise, setNum: Int) {
        currentEditingExName = ex.name
        currentEditingSetNum = setNum
        
        let driverName = UserDefaults.standard.string(forKey: "driverName") ?? "GUEST"
        FirebaseManager.shared.updateLiveTelemetry(ownerName: driverName, routineTitle: routine.title, exercise: ex.name, set: setNum)
        
        if let currentSessionSets = sessionManager.completedSets[ex.name], let lastSetRecord = currentSessionSets[setNum] {
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
    
    func isExerciseCompleted(ex: RoutineExercise) -> Bool {
        guard let sets = sessionManager.completedSets[ex.name] else { return false }
        for setNum in 1...ex.sets { if sets[setNum] == nil { return false } }
        return true
    }
}

// MARK: - リザルト画面 (ResultView)
struct ResultView: View {
    @Environment(\.modelContext) var modelContext
    let routine: WorkoutRoutine
    let activeExercises: [RoutineExercise]
    let completedSets: [String: [Int: SetRecord]]
    let secondsElapsed: Int
    let calculateTotalVolume: Double
    @Binding var isRootActive: Bool
    
    @State private var showShareCockpit = false // 💥 追加：シェア用コックピット
    
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.5).ignoresSafeArea()
            
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
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showShareCockpit = true
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("POST TO FEED")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(routine.themeColor.toColor)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    Button {
                        let ownerName = UserDefaults.standard.string(forKey: "driverName") ?? "GUEST"
                        let newLog = WorkoutLog(dayTitle: routine.title, totalSeconds: secondsElapsed, themeColor: routine.themeColor, ownerName: ownerName)
                        
                        for ex in activeExercises {
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
                        FirebaseManager.shared.uploadWorkoutLog(newLog)
                        FirebaseManager.shared.clearLiveTelemetry(ownerName: ownerName)
                        UserStatusManager.shared.finishTraining()
                        
                        WorkoutSessionManager.shared.endSession()
                        isRootActive = false
                    } label: {
                        Text("Return to Garage").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(routine.themeColor.toColor).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 40)
            }
        }
        .sheet(isPresented: $showShareCockpit) {
            ShareCockpitView(
                routineName: routine.title,
                routineID: routine.id.uuidString,
                driverName: UserDefaults.standard.string(forKey: "driverName") ?? "GUEST",
                totalVolume: Int(calculateTotalVolume),
                totalTime: formatTime(secondsElapsed),
                themeColor: routine.themeColor.toColor,
                isPublic: routine.isPublic, // 💥 追加
                onPosted: {
                    // 💥 投稿完了後に自動でガレージに戻る
                    FirebaseManager.shared.clearLiveTelemetry(ownerName: UserDefaults.standard.string(forKey: "driverName") ?? "GUEST")
                    UserStatusManager.shared.finishTraining()
                    WorkoutSessionManager.shared.endSession()
                    isRootActive = false
                }
            )
        }
    }
    func formatTime(_ s: Int) -> String { String(format: "%02d:%02d", s / 60, s % 60) }
}

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

struct WorkoutCardView: View {
    @Bindable var ex: RoutineExercise
    let isExerciseCompleted: Bool
    let completedSets: [Int: SetRecord]
    let themeColor: Color
    var onMoveUp: (() -> Void)? = nil // 💥 並び替え用
    var onMoveDown: (() -> Void)? = nil // 💥 並び替え用
    let onSetTapped: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                NavigationLink(destination: ExerciseHistoryView(exerciseName: ex.name)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ex.name)
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.horizontal.fill").font(.caption2).foregroundColor(themeColor)
                            Text(ex.target).font(.custom("AvenirNext-Medium", size: 12)).foregroundColor(.gray)
                            if ex.equipment != "なし" && ex.equipment != "その他" {
                                Text("・ \(ex.equipment)").font(.custom("AvenirNext-Medium", size: 12)).foregroundColor(.gray)
                            }
                        }
                    }
                }.buttonStyle(.plain)
                
                Spacer(minLength: 10)
                
                HStack(spacing: 12) {
                    // 並び替えボタン
                    VStack(spacing: 4) {
                        if let onMoveUp = onMoveUp {
                            Button(action: onMoveUp) { Image(systemName: "chevron.up").font(.caption.bold()).foregroundColor(.gray.opacity(0.6)) }
                        }
                        if let onMoveDown = onMoveDown {
                            Button(action: onMoveDown) { Image(systemName: "chevron.down").font(.caption.bold()).foregroundColor(.gray.opacity(0.6)) }
                        }
                    }
                    .padding(.trailing, 4)

                    Text("\(ex.sets) SETS")
                        .font(.custom("AvenirNext-Bold", size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color(white: 0.8))
                        .cornerRadius(4)
                }
            }
            
            VStack {
                MissionShiftView(
                    totalSets: ex.sets,
                    completedSetsCount: completedSets.keys.count,
                    themeColor: themeColor,
                    onShiftUp: { (setNum: Int) in onSetTapped(setNum) },
                    onShiftDown: { (setNum: Int) in onSetTapped(setNum) }
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .padding(24)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.6), radius: 15, x: 0, y: 10)
        .overlay(
            VStack {
                if isExerciseCompleted {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(themeColor)
                            .font(.system(size: 32))
                            .padding(12)
                    }
                    Spacer()
                }
            }
        )
    }
}

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
        let points = [CGSize(width: min(max(target.width, -colW), colW), height: 0),
                      CGSize(width: -colW, height: min(max(target.height, -rowH), rowH)),
                      CGSize(width: 0, height: min(max(target.height, -rowH), rowH)),
                      CGSize(width: colW, height: min(max(target.height, -rowH), rowH))]
        var closestPoint = target; var minDistance: CGFloat = .infinity
        for p in points {
            let d = hypot(target.width - p.width, target.height - p.height)
            if d < minDistance { minDistance = d; closestPoint = p }
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
            bolts; gearNumbers; shiftKnob
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
            let angle = Angle.degrees(Double(i) * 60.0 + 30.0); let x = cos(angle.radians) * radius; let y = sin(angle.radians) * radius
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
            
            // 💥 変更：ドラッグ中は常にギア番号を表示、静止時はDONE判定を優先
            if isDragging {
                Text(currentGear == 0 ? "N" : "\(currentGear)")
                    .font(.custom("AvenirNext-Heavy", size: 24))
                    .foregroundColor(themeColor)
                    .shadow(color: themeColor.opacity(0.5), radius: 3)
            } else if currentGear >= totalSets && totalSets > 0 {
                Text("DONE")
                    .font(.custom("AvenirNext-Heavy", size: 16))
                    .foregroundColor(themeColor)
                    .shadow(color: themeColor.opacity(0.5), radius: 3)
            }
        }
        .offset(dragOffset).gesture(shiftGesture)
    }
    private var shiftGesture: some Gesture {
        DragGesture(minimumDistance: 0).onChanged { value in
            if !isDragging { isDragging = true; ShiftSoundManager.shared.playShiftDragStart() }
            let rawOffset = CGSize(width: baseOffset.width + value.translation.width, height: baseOffset.height + value.translation.height)
            let clampedOffset = clampToHPattern(target: rawOffset)
            let hapticDist = hypot(clampedOffset.width - lastHapticOffset.width, clampedOffset.height - lastHapticOffset.height)
            if hapticDist > 15 { HardwareManager.shared.playSelection(); lastHapticOffset = clampedOffset }
            if abs(clampedOffset.height) < 5 && abs(dragOffset.height) >= 5 { HardwareManager.shared.playMedium() }
            dragOffset = clampedOffset
        }.onEnded { value in
            isDragging = false; let rawOffset = CGSize(width: baseOffset.width + value.translation.width, height: baseOffset.height + value.translation.height)
            let finalOffset = clampToHPattern(target: rawOffset); let targetUp = currentGear + 1; let targetDown = currentGear - 1
            let posUp = position(for: targetUp); let posDown = position(for: targetDown)
            let distUp = hypot(finalOffset.width - posUp.width, finalOffset.height - posUp.height); let distDown = hypot(finalOffset.width - posDown.width, finalOffset.height - posDown.height)
            // 💥 変更：targetUp <= 6 の制限
            if distUp < 35 && targetUp <= 6 {
                HardwareManager.shared.playHeavy(); ShiftSoundManager.shared.playShiftUpSequence(gear: targetUp)
                currentGear = targetUp; baseOffset = posUp; withAnimation(mechanicalSpring) { dragOffset = posUp }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onShiftUp(targetUp) }
            } else if distDown < 35 && targetDown >= 1 {
                HardwareManager.shared.playHeavy(); ShiftSoundManager.shared.playShiftDownSequence(gear: targetDown)
                currentGear = targetDown; baseOffset = posDown; withAnimation(mechanicalSpring) { dragOffset = posDown }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onShiftDown(targetDown) }
            } else { HardwareManager.shared.playRigid(); withAnimation(mechanicalSpring) { dragOffset = baseOffset } }
        }
    }
    func syncState() {
        // 💥 変更：totalSets を超えた分も考慮して同期
        currentGear = min(completedSetsCount, 6); baseOffset = position(for: currentGear); dragOffset = baseOffset; lastHapticOffset = baseOffset
    }
}

// 💥 ShareResultImageView は別ファイルへ移動したため削除
extension WorkoutDetailView {
    @ViewBuilder
    func pitRadioView(rec: PitRadioEngine.Recommendation) -> some View {
        VStack(spacing: 24) {
            // ヘッダー：無線アイコン
            HStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title)
                    .foregroundColor(rec.color)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                
                Text("PIT RADIO")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // バッジ
                Text("ENGINEER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(rec.color)
                    .cornerRadius(4)
            }
            
            // ステータス表示
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("STRATEGY").font(.caption.weight(.bold)).foregroundColor(.gray)
                    Text(rec.action == .shiftUp ? "SHIFT UP" : (rec.action == .shiftDown ? "SHIFT DOWN" : "STAY"))
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(rec.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ADJUST").font(.caption.weight(.bold)).foregroundColor(.gray)
                    Text(rec.suggestedAdjustment)
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.top, 8)
            
            // メッセージ本文
            Text(typingMessage) // 💥 タイピング効果を適用
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(rec.color.opacity(0.2), lineWidth: 1))
            
            // 了解ボタン
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring()) { showPitRadio = false }
            } label: {
                Text("COPY THAT")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(rec.color)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.1)
                // 走査線のようなテクスチャ
                VStack(spacing: 4) {
                    ForEach(0..<40) { _ in
                        Rectangle().fill(Color.white.opacity(0.02)).frame(height: 1)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(rec.color.opacity(0.4), lineWidth: 2))
        .shadow(color: rec.color.opacity(0.2), radius: 30, y: 15)
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.1).combined(with: .opacity), // 💥 中央から拡大
            removal: .scale(scale: 1.05).combined(with: .opacity)
        ))
    }
}
