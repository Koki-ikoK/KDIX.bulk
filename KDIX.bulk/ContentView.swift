import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AudioToolbox
import AVFoundation

// MARK: - 🎵 1. サウンドマネージャー（音量制御・プロ仕様）
class ProSoundManager {
    static let shared = ProSoundManager()
    private var enginePlayer: AVAudioPlayer?
    
    init() {
        if let url = Bundle.main.url(forResource: "engine_rev", withExtension: "mp3") {
            enginePlayer = try? AVAudioPlayer(contentsOf: url)
            enginePlayer?.numberOfLoops = -1 // ループ再生
            enginePlayer?.prepareToPlay()
        }
    }
    
    func startEngine() {
            // 💥 AppStorage ではなく AppSettings.shared を使う！
            guard AppSettings.shared.isEngineSoundEnabled else { return }
            
            enginePlayer?.volume = 0.0
            enginePlayer?.play()
        }
    
    func setVolume(_ volume: Float) {
        enginePlayer?.volume = volume
    }
    
    func stopEngine() {
        enginePlayer?.setVolume(0, fadeDuration: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.enginePlayer?.stop()
        }
    }
    
    func playShiftImpact() {
        AudioServicesPlaySystemSound(1521)
    }
}

// MARK: - 🧭 2. ナビゲーション先をまとめるEnum（バグ完全回避・Hashable対応！）
enum SelectionNavTarget: Identifiable, Hashable {
    case detail(WorkoutRoutine)
    case builder
    case edit(WorkoutRoutine)
    
    var id: String {
        switch self {
        case .detail(let r): return "detail_\(r.id)"
        case .builder: return "builder"
        case .edit(let r): return "edit_\(r.id)"
        }
    }
    
    static func == (lhs: SelectionNavTarget, rhs: SelectionNavTarget) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 🎨 3. String拡張（Color変換）
extension String {
    var toColor: Color {
        switch self.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .blue
        }
    }
}
// MARK: - 🏠 4. ホーム画面 (ContentView)
struct ContentView: View {
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    @Query private var routines: [WorkoutRoutine]
    @Environment(\.modelContext) private var context
    
    @State private var isNavigatingToSelection = false
    @State private var isResumingWorkout = false
    @State private var showNitroCockpit = false
    @State private var isNitroBlowing = false
    @ObservedObject private var nitroManager = NitroManager.shared
    
    @State private var activeDraftRoutine: WorkoutRoutine? = nil
    @State private var selectedLog: WorkoutLog? = nil
    
    @AppStorage("nitrousCount") private var nitrousCount = 2
    @State private var selectedTab = 0
    
    // 💥 追加：設定画面の表示フラグ
    @State private var showSettings = false
    
    @ObservedObject private var statusManager = UserStatusManager.shared
    @State private var isBlinking = false

    var isTodayWorkoutCompleted: Bool { workoutLogs.contains { Calendar.current.isDateInToday($0.date) } }

    var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDates = Set(workoutLogs.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        if uniqueDates.isEmpty { return 0 }
        var streak = 0; var targetDate = calendar.startOfDay(for: Date())
        if !uniqueDates.contains(targetDate) { targetDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!; if !uniqueDates.contains(targetDate) { return 0 } }
        for date in uniqueDates { if date == targetDate { streak += 1; targetDate = calendar.date(byAdding: .day, value: -1, to: targetDate)! } else { break } }
        return streak
    }
    
    var totalVolume: Int { Int(workoutLogs.reduce(0) { $0 + $1.totalVolume }) }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🏎️ TAB 1: ガレージ（メイン画面）
            NavigationStack {
                ZStack {
                    LinearGradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.1), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    CarbonFiberBackground().ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SYSTEM ID: IWAKI").font(.footnote.weight(.bold)).foregroundColor(.gray)
                                Text("Garage").font(.system(.largeTitle, design: .rounded).weight(.heavy)).foregroundColor(.white)
                            }
                            Spacer()
                            
                            // 💥 変更：ただの画像からボタンに変更！
                            Button {
                                if AppSettings.shared.isHapticEnabled {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                                showSettings = true
                            } label: {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            }
                        }
                        .padding(.horizontal, 24).padding(.top, 10)
                        HStack(spacing: 8){
                            Circle()
                                .fill(statusManager.currentStatus.color)
                                .frame(width: 8, height: 8)
                                .opacity(statusManager.currentStatus == .training ? (isBlinking ? 0.3 : 1.0) : 1.0)
                            Text("STATUS \(statusManager.currentStatus.rawValue)")
                            font(.system(size: 11, weight: .bold,  design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 24).padding(.top, 4)
                        .onAppear{
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)){
                                isBlinking = true
                            }
                        }
                        
                        Spacer(minLength: 10)
                        
                        // カスタムのダッシュボードView (もしエラーが出たら下の DashboardMetricsView に置き換えてください)
                        FuriousDashboardView(
                            currentStreak: currentStreak,
                            totalVolume: totalVolume,
                            nosCount: nitroManager.nitrousCount,
                            onNosTapped: {
                                // 💥 ここを変更：タップしたらコックピット画面を開く！
                                if nitroManager.nitrousCount > 0 {
                                    if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                                    showNitroCockpit = true
                                }
                            }
                        )
                        
                        Spacer(minLength: 20)
                        
                        VStack {
                            if isTodayWorkoutCompleted {
                                Button {
                                    if AppSettings.shared.isHapticEnabled {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                    isNavigatingToSelection = true
                                } label: {
                                    VStack(spacing: 6) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.seal.fill").font(.headline)
                                            Text("本日のワークアウト完了").font(.system(.title3, design: .rounded).weight(.bold))
                                        }
                                        Text("追加トレーニング").font(.caption.weight(.semibold)).opacity(0.8)
                                    }
                                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                                    .background(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).shadow(color: Color.green.opacity(0.4), radius: 15, x: 0, y: 8)
                                }
                            } else {
                                EngineStartButton(action: {
                                    isNavigatingToSelection = true
                                })
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 20)
                    }
                }
                .navigationDestination(isPresented: $isNavigatingToSelection) { WorkoutSelectionView(isRootActive: $isNavigatingToSelection) }
                .navigationDestination(isPresented: $isResumingWorkout) { if let routine = activeDraftRoutine { WorkoutDetailView(routine: routine, isRootActive: $isResumingWorkout) } }
                
                // 💥 追加：設定画面をハーフモーダルで呼び出し！
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .presentationDetents([.medium, .large]) // 画面の半分、または全画面に広がる最新UI
                        .presentationDragIndicator(.visible)    // 上のつまみを表示
                }
                .fullScreenCover(isPresented: $showNitroCockpit){
                    NitroCockpitView()
                }
            }
            .tabItem { Label("Garage", systemImage: "car.fill") }
            .tag(0)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
            
            // 📅 TAB 2: ログ
            NavigationStack {
                ZStack {
                    Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 24) {
                            MonthlyActivityView(logs: workoutLogs).padding(.horizontal, 20)
                            if !workoutLogs.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recent Workouts").font(.title3.weight(.bold)).padding(.horizontal, 24)
                                    ForEach(workoutLogs.prefix(10)) { log in
                                        Button {
                                            if AppSettings.shared.isHapticEnabled {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                            selectedLog = log
                                        } label: {
                                            RecentWorkoutRow(log: log) { withAnimation(.spring()) { context.delete(log) } }
                                        }
                                        .buttonStyle(.plain).padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 20).padding(.bottom, 80)
                    }
                }
                .navigationTitle("History")
                .navigationDestination(item: $selectedLog) { log in WorkoutLogDetailView(log: log) }
            }
            .tabItem { Label("Log", systemImage: "calendar") }
            .tag(1)
        }
        .onAppear { checkActiveDraft() }
    }
    
    func checkActiveDraft() {
        if let activeIdStr = UserDefaults.standard.string(forKey: "activeWorkoutId"), let activeId = UUID(uuidString: activeIdStr), let activeRoutine = routines.first(where: { $0.id == activeId }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.activeDraftRoutine = activeRoutine; self.isResumingWorkout = true }
        }
    }
}

// MARK: - 🏁 5. CarbonFiberBackground
struct CarbonFiberBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for x in stride(from: 0, to: geometry.size.width, by: 4) {
                    for y in stride(from: 0, to: geometry.size.height, by: 4) {
                        path.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
            }
            .fill(Color.white.opacity(0.03))
        }
    }
}

// MARK: - 🔴 6. EngineStartButton & Style
struct EngineStartButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            action()
        }) {
            ZStack {
                Circle().fill(Color.red).frame(width: 130, height: 130).blur(radius: 15).opacity(0.7)
                Circle().fill(LinearGradient(colors: [Color(white: 0.9), Color(white: 0.4), Color(white: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 130, height: 130).shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 8)
                Circle().fill(LinearGradient(colors: [Color(white: 0.1), Color(white: 0.3)], startPoint: .top, endPoint: .bottom)).frame(width: 114, height: 114)
                Circle().fill(RadialGradient(colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.6, green: 0.0, blue: 0.0)], center: .top, startRadius: 10, endRadius: 80)).frame(width: 108, height: 108).shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: -2)
                Circle().fill(LinearGradient(colors: [Color.white.opacity(0.6), Color.clear], startPoint: .top, endPoint: .center)).frame(width: 96, height: 96).offset(y: -4).blendMode(.overlay)
                
                VStack(spacing: -2) {
                    Text("ENGINE").font(.system(size: 14, weight: .black, design: .rounded))
                    Text("START").font(.system(size: 22, weight: .black, design: .rounded))
                }
                .foregroundColor(.white).shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            }
        }
        .buttonStyle(EngineStartButtonStyle())
    }
}

struct EngineStartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.92 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 📖 7. WorkoutLogDetailView
struct WorkoutLogDetailView: View {
    let log: WorkoutLog
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volume").font(.subheadline).foregroundColor(.secondary)
                        Text("\(Int(log.totalVolume)) kg").font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(.orange)
                    }
                    Spacer()
                    Divider().frame(height: 40)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Time").font(.subheadline).foregroundColor(.secondary)
                        Text(formatTime(log.totalSeconds)).font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(.primary)
                    }
                }
                .padding(20).background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                VStack(spacing: 16) {
                    ForEach(log.exercises) { ex in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(ex.name).font(.headline).foregroundColor(log.themeColor.toColor)
                            VStack(spacing: 8) {
                                ForEach(ex.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                                    HStack {
                                        Text("Set \(set.setNumber)").font(.subheadline).foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(set.weight))kg × \(set.reps)回").font(.subheadline.bold())
                                    }
                                }
                            }
                        }
                        .padding(20).background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(log.dayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatTime(_ s: Int) -> String { String(format: "%02d:%02d", s / 60, s % 60) }
}

// MARK: - ⚙️ 8. メニュー選択画面 (WorkoutSelectionView)
struct WorkoutSelectionView: View {
    @Binding var isRootActive: Bool
    @Query private var routines: [WorkoutRoutine]
    @Environment(\.modelContext) private var context
    @State private var selectedRoutine: WorkoutRoutine? = nil
    
    @State private var navTarget: SelectionNavTarget? = nil
    @State private var quickStartEffect: Double = 0.0
    @State private var customEffect: Double = 0.0

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.07), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            CarbonFiberBackground().opacity(0.3).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("ワークアウトを選択")
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.top, 20)
                    
                    HStack(spacing: 16) {
                        // ⚡️ QUICK START
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            quickStartEffect = 1.0
                            withAnimation(.easeOut(duration: 0.5)) { quickStartEffect = 0.0 }
                            
                            let timeString = Date().formatted(date: .omitted, time: .shortened)
                            let newRoutine = WorkoutRoutine(title: "クイックスタート (\(timeString))", themeColor: "cyan")
                            selectedRoutine = newRoutine
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navTarget = .detail(newRoutine)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill").foregroundColor(.yellow).font(.title3)
                                Text("QUICK START").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                                Spacer()
                            }
                            .padding().background(Color(white: 0.12)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cyan, lineWidth: 4).scaleEffect(1.0 + ((1.0 - quickStartEffect) * 0.3)).opacity(quickStartEffect))
                        
                        // 🔧 CUSTOM
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            customEffect = 1.0
                            withAnimation(.easeOut(duration: 0.4)) { customEffect = 0.0 }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navTarget = .builder
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill").foregroundColor(.cyan).font(.title3)
                                Text("CUSTOM").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                                Spacer()
                            }
                            .padding().background(Color(white: 0.12)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.yellow).opacity(customEffect * 0.4))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.yellow, lineWidth: 3).scaleEffect(1.0 + ((1.0 - customEffect) * 0.1)).opacity(customEffect))
                    }.padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        if routines.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: 40)).foregroundColor(.gray.opacity(0.3))
                                Text("No Custom Routines").font(.subheadline.bold()).foregroundColor(.gray)
                            }.padding(.top, 40).frame(maxWidth: .infinity)
                        } else {
                            ForEach(routines) { routine in
                                RoutineCard(routine: routine, isSelected: selectedRoutine == routine)
                                    .contextMenu {
                                        Button { navTarget = .edit(routine) } label: { Label("Edit Routine", systemImage: "pencil") }
                                        Button(role: .destructive) { context.delete(routine) } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        // 👇 タップした時にアニメーションを適用
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedRoutine = routine
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    // 👇 ペダルが出ている時だけ下の余白を増やす！
                    .padding(.bottom, selectedRoutine != nil ? 280 : 100)
                }
            }
            
            // 👇 ルーティンが選ばれた時「だけ」ペダルを下から出現させる
            if let routine = selectedRoutine {
                WorkoutStartPedalView(
                    activeNeonColor: routine.themeColor.toColor,
                    isSelected: true,
                    onComplete: {
                        navTarget = .detail(routine)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity)) // 下からスッと出す
                .zIndex(2)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navTarget) { target in
            switch target {
            case .detail(let routine):
                WorkoutDetailView(routine: routine, isRootActive: $isRootActive)
            case .builder:
                RoutineBuilderView()
            case .edit(let routine):
                RoutineBuilderView(routineToEdit: routine)
            }
        }
    }
}

// MARK: - 🦶 9. アクセルペダル View (加速＆レブリミッター振動 搭載版)
struct WorkoutStartPedalView: View {
    let activeNeonColor: Color
    let isSelected: Bool
    var onComplete: () -> Void
    
    @State private var pressProgress: CGFloat = 0.0
    @State private var isPressing: Bool = false
    @State private var isRedZoneFlash: Bool = false
    @State private var timer: Timer? = nil
    
    // 👇 追加：レッドゾーンでのバウンド回数をカウント
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
                if pressProgress < 1.0 && revCount == 0 {
                    pressProgress += 0.04
                    ProSoundManager.shared.setVolume(Float(pressProgress))
                    
                    // 💥 1箇所目：踏み込み中の振動をガード
                    if AppSettings.shared.isHapticEnabled {
                        if Int(pressProgress * 100) % 10 == 0 {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: pressProgress)
                        }
                    }
                    
                    if pressProgress > 0.8 {
                        withAnimation(.easeInOut(duration: 0.1)) { isRedZoneFlash.toggle() }
                    }
                } else {
                    revCount += 1
                    withAnimation(.linear(duration: 0.02)) {
                        pressProgress = CGFloat.random(in: 0.96...1.04)
                    }
                    
                    // 💥 2箇所目：レッドゾーン（レブリミッター）の振動をガード
                    if AppSettings.shared.isHapticEnabled {
                        if revCount % 2 == 0 {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 1.0)
                        }
                    }
                    
                    if revCount >= 20 {
                        pressProgress = 1.0
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
        
        UserStatusManager.shared.startTraining()
        
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

// MARK: - 📋 12. RoutineCard (ネオンカラー連動版)
struct RoutineCard: View {
    let routine: WorkoutRoutine
    let isSelected: Bool
    
    // そのルーティンが持っている色を取得
    private var routineColor: Color {
        routine.themeColor.toColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 🏎️ 左側のインジケーター線をルーティンの色に変更
            Rectangle()
                .fill(isSelected ? routineColor : Color.clear)
                .frame(width: 4)
                .cornerRadius(2)
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                // 🏎️ アイコンの色を連動
                Image(systemName: "engine.combustion.fill")
                    .font(.headline)
                    .foregroundColor(isSelected ? routineColor : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundColor(isSelected ? .white : Color(white: 0.8))
                
                Text(routine.exercises.first?.name != nil ? "\(routine.exercises.first!.name) など全\(routine.exercises.count)種目" : "種目なし")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? .gray : .gray.opacity(0.7))
            }
            Spacer()
            
            if isSelected {
                // 🏎️ チェックマークの色を連動
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(routineColor)
                    .font(.title2)
            }
        }
        .padding(.vertical, 14)
        .padding(.trailing, 16)
        // 🏎️ カード全体の背景発光を連動
        .background(isSelected ? routineColor.opacity(0.1) : Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            // 🏎️ 枠線の色を連動（これが「枠に沿った色付き線」です）
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? routineColor.opacity(0.6) : Color.white.opacity(0.05), lineWidth: 1)
        )
        // 🏎️ 選択時にうっすら外側に光が漏れるエフェクトを追加（Liquid Glass感）
        .shadow(color: isSelected ? routineColor.opacity(0.2) : .clear, radius: 10, x: 0, y: 0)
    }
}

// MARK: - 📊 13. DashboardMetricsView / MetricCard
struct DashboardMetricsView: View {
    let logs: [WorkoutLog]
    var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDates = Set(logs.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        if uniqueDates.isEmpty { return 0 }
        var streak = 0; var targetDate = calendar.startOfDay(for: Date())
        if !uniqueDates.contains(targetDate) { targetDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!; if !uniqueDates.contains(targetDate) { return 0 } }
        for date in uniqueDates { if date == targetDate { streak += 1; targetDate = calendar.date(byAdding: .day, value: -1, to: targetDate)! } else { break } }
        return streak
    }
    var body: some View {
        HStack(spacing: 16) {
            MetricCard(icon: "flame.fill", color1: .orange, color2: .red, value: "\(currentStreak)", title: "Day Streak")
            MetricCard(icon: "dumbbell.fill", color1: .blue, color2: .cyan, value: "\(logs.count)", title: "Total Workouts")
        }
    }
}

struct MetricCard: View {
    let icon: String; let color1: Color; let color2: Color; let value: String; let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient(colors: [color1.opacity(0.2), color2.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.title3).foregroundStyle(LinearGradient(colors: [color1, color2], startPoint: .top, endPoint: .bottom))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.system(size: 28, weight: .heavy, design: .rounded))
                Text(title).font(.caption.weight(.bold)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 5)
    }
}

// MARK: - 📆 14. MonthlyActivityView
struct MonthlyActivityView: View {
    let logs: [WorkoutLog]
    let daysInWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var daysInMonth: [Date] {
        let calendar = Calendar.current; let range = calendar.range(of: .day, in: .month, for: Date())!
        let components = calendar.dateComponents([.year, .month], from: Date()); let startOfMonth = calendar.date(from: components)!
        return range.compactMap { day -> Date? in calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Activity").font(.headline.weight(.bold)).foregroundColor(.primary)
            
            HStack(spacing: 0) {
                ForEach(0..<daysInWeek.count, id: \.self) { index in
                    Text(daysInWeek[index]).font(.system(size: 10, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 12) {
                let firstDayWeekday = Calendar.current.component(.weekday, from: daysInMonth.first!)
                ForEach(0..<firstDayWeekday - 1, id: \.self) { _ in Color.clear.frame(height: 24) }
                ForEach(daysInMonth, id: \.self) { date in
                    let logForDate = logs.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    let isDone = logForDate != nil
                    let isToday = Calendar.current.isDateInToday(date)
                    let markColor: Color = logForDate?.themeColor.toColor ?? .secondary.opacity(0.15)
                    
                    ZStack {
                        Circle().fill(isDone ? markColor : Color.clear).frame(width: 28, height: 28)
                        Text("\(Calendar.current.component(.day, from: date))").font(.caption2.weight(isDone || isToday ? .bold : .regular)).foregroundColor(isDone ? .white : (isToday ? .blue : .primary))
                        if isToday && !isDone { Circle().stroke(Color.blue, lineWidth: 2).frame(width: 28, height: 28) }
                    }
                }
            }
        }
        .padding(20).background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 5)
    }
}

// MARK: - ⏱️ 15. RecentWorkoutRow
struct RecentWorkoutRow: View {
    let log: WorkoutLog
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(log.themeColor.toColor.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "checkmark.seal.fill").foregroundColor(log.themeColor.toColor).font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(log.dayTitle).font(.headline).foregroundColor(.primary)
                Text(log.date, style: .date).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(log.totalVolume)) kg").font(.system(.headline, design: .rounded).bold()).foregroundColor(.primary)
                Text("Volume").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(16).background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }
}
// MARK: - ⚙️ 16. アプリ設定マネージャー (AppSettings)
// 💥 修正：ObservableObjectと@AppStorageを廃止し、純粋なUserDefaults読み取り専用クラスに変更
class AppSettings {
    static let shared = AppSettings()
    
    var isEngineSoundEnabled: Bool { UserDefaults.standard.bool(forKey: "isEngineSoundEnabled") }
    var isShiftSoundEnabled: Bool { UserDefaults.standard.bool(forKey: "isShiftSoundEnabled") }
    var isHapticEnabled: Bool { UserDefaults.standard.bool(forKey: "isHapticEnabled") }
    
    private init() {
        // アプリ初回起動時のデフォルト値を「オン（true）」にセット
        UserDefaults.standard.register(defaults: [
            "isEngineSoundEnabled": true,
            "isShiftSoundEnabled": true,
            "isHapticEnabled": true
        ])
    }
}

// MARK: - 🔧 17. 設定画面 (SettingsView)
struct SettingsView: View {
    // 💥 修正：UI（View）側で直接 @AppStorage を宣言するのがSwiftUIの正しい書き方！
    @AppStorage("isEngineSoundEnabled") var isEngineSoundEnabled = true
    @AppStorage("isShiftSoundEnabled") var isShiftSoundEnabled = true
    @AppStorage("isHapticEnabled") var isHapticEnabled = true
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("SOUND & HAPTIC").font(.custom("AvenirNext-Bold", size: 12))) {
                    Toggle(isOn: $isEngineSoundEnabled) {
                        Label("エンジン音", systemImage: "engine.combustion.fill")
                    }
                    
                    Toggle(isOn: $isShiftSoundEnabled) {
                        Label("シフト・ターボ音", systemImage: "speaker.wave.3.fill")
                    }
                    
                    Toggle(isOn: $isHapticEnabled) {
                        Label("振動フィードバック", systemImage: "iphone.radiowaves.left.and.right")
                    }
                }
                .listRowBackground(Color(white: 0.15))
                .foregroundColor(.white)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("SETTINGS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isHapticEnabled {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        dismiss()
                    } label: {
                        Text("完了")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
    }
}
