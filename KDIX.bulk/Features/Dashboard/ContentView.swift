import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AudioToolbox
import AVFoundation

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
}

// MARK: - 🌈 3. Color拡張（文字列から色への変換用）
extension String {
    var toColor: Color {
        switch self {
        case "cyan": return .cyan
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "yellow": return .yellow
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
    @ObservedObject private var nitroManager = NitroManager.shared // 💥 復活
    
    @State private var activeDraftRoutine: WorkoutRoutine? = nil
    @State private var selectedLog: WorkoutLog? = nil
    
    @AppStorage("safetyCarShields") private var safetyCarShields = 2 
    @AppStorage("driverName") var driverName = "GUEST"
    @AppStorage("sentNitrosToday") private var sentNitrosToday: String = "" 
    @AppStorage("lastNitroResetDate") private var lastNitroResetDate: String = "" 
    
    @StateObject private var sessionManager = WorkoutSessionManager.shared
    @State private var showFullWorkout = false
    @State private var selectedTab = 0
    
    // 💥 追加：設定画面の表示フラグ
    @State private var showSettings = false
    
    // 💥 追加：初回ログインフラグ
    @State private var showOnboarding = false
    
    var isTodayWorkoutCompleted: Bool { workoutLogs.contains { Calendar.current.isDateInToday($0.date) } }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let uniqueDates = Set(workoutLogs.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        if uniqueDates.isEmpty { return 0 }
        
        // 直近のトレーニングが今日でも昨日でもない場合はストリーク終了
        guard let lastTrainingDate = uniqueDates.first,
              lastTrainingDate == today || lastTrainingDate == yesterday else {
            return 0
        }
        
        var streak = 0
        var targetDate = lastTrainingDate
        
        for date in uniqueDates {
            if date == targetDate {
                streak += 1
                targetDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!
            } else {
                break
            }
        }
        return streak
    }
    
    var totalVolume: Int { workoutLogs.reduce(0) { $0 + Int($1.totalVolume) } }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 🏎️ TAB 1: ガレージ
            NavigationStack {
                ZStack {
                    LinearGradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.1), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    CarbonFiberBackground().ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        headerSection
                        BlinkingStatusView().padding(.horizontal, 24).padding(.top, 4)
                        Spacer(minLength: 10)
                        
                        FuriousDashboardView(
                            currentStreak: currentStreak,
                            totalVolume: totalVolume,
                            shieldCount: safetyCarShields,
                            onShieldTapped: {
                                if safetyCarShields > 0 {
                                    if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                                    safetyCarShields -= 1
                                }
                            },
                            onStartWorkout: { isNavigatingToSelection = true }
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        VStack {
                            if sessionManager.activeRoutine == nil {
                                if isTodayWorkoutCompleted {
                                    Button {
                                        if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
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
                                    EngineStartButton(action: { isNavigatingToSelection = true })
                                }
                            } else {
                                Color.clear.frame(height: 72)
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 20)
                    }
                }
                .navigationDestination(isPresented: $isNavigatingToSelection) {
                    WorkoutSelectionView(isRootActive: $isNavigatingToSelection, showFullWorkout: $showFullWorkout)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .fullScreenCover(isPresented: $showNitroCockpit){ NitroCockpitView() }
            }
            .tabItem { Label("Garage", systemImage: "car.fill") }
            .tag(0)
            
            CalendarDashboardView(
                logs: workoutLogs,
                currentStreak: currentStreak,
                totalVolume: totalVolume,
                shieldCount: safetyCarShields,
                onShieldTapped: {
                    if safetyCarShields > 0 {
                        selectedTab = 0;
                    }
                },
                onStartWorkout: { selectedTab = 0; isNavigatingToSelection = true }
            )
            .tabItem{Label("Stats", systemImage: "chart.bar.xaxis")}
            .tag(1)
            
            CommunityFeedView()
                .tabItem{Label("Feed", systemImage: "antenna.radiowaves.left.and.right")}
                .tag(2)
        }
        .overlay(alignment: .bottom) {
            if sessionManager.activeRoutine != nil && !showFullWorkout {
                activeWorkoutMiniBar
            }
        }
        .fullScreenCover(isPresented: $showFullWorkout) {
            if let routine = sessionManager.activeRoutine {
                NavigationStack {
                    WorkoutDetailView(routine: routine, isRootActive: $showFullWorkout)
                }
            }
        }
        .onAppear {
            checkActiveDraft()
            checkNitroReset()
            if driverName == "GUEST" || driverName.isEmpty { 
                showOnboarding = true 
            } else {
                FirebaseManager.shared.registerDriver(name: driverName) // 💥 既存ユーザの登録
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(driverName: $driverName)
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("SYSTEM ID: \(driverName.uppercased())").font(.footnote.weight(.bold)).foregroundColor(.gray)
                    let currentLicense = DriverLicense.getLicense(for: totalVolume)
                    Text(currentLicense.rawValue)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(currentLicense.color.opacity(0.2))
                        .foregroundColor(currentLicense.color)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(currentLicense.color, lineWidth: 1))
                }
                Text("Garage").font(.system(.largeTitle, design: .rounded).weight(.heavy)).foregroundColor(.white)
            }
            Spacer()
            Button {
                if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                showSettings = true
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
        .padding(.horizontal, 24).padding(.top, 10)
    }

    private var activeWorkoutMiniBar: some View {
        VStack(spacing: 0) {
            Spacer()
            Button {
                withAnimation(.spring()) { showFullWorkout = true }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(.white.opacity(0.2)).frame(width: 36, height: 36)
                        Image(systemName: "bolt.fill").foregroundColor(.white).font(.system(size: 16, weight: .black))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACTIVE MISSION").font(.system(size: 10, weight: .black)).foregroundColor(.white.opacity(0.8))
                        Text(sessionManager.activeRoutine?.title ?? "Workout").font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white).lineLimit(1)
                    }
                    Spacer()
                    IsolatedTimerView(startTime: sessionManager.sessionStartTime, initialSeconds: sessionManager.initialSecondsElapsed).font(.system(size: 24, weight: .black, design: .monospaced)).foregroundColor(.white)
                }
                .padding(.horizontal, 24).frame(maxWidth: .infinity).frame(height: 72)
                .background(LinearGradient(colors: [sessionManager.activeRoutine?.themeColor.toColor ?? .blue, .black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: (sessionManager.activeRoutine?.themeColor.toColor ?? .blue).opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 24).padding(.bottom, 80)
        }
        .allowsHitTesting(true)
        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
    }
    
    func checkActiveDraft() {
        if let activeIdStr = UserDefaults.standard.string(forKey: "activeWorkoutId"), 
           let activeId = UUID(uuidString: activeIdStr), 
           let activeRoutine = routines.first(where: { $0.id == activeId }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
                WorkoutSessionManager.shared.startSession(with: activeRoutine)
            }
        }
    }

    func checkNitroReset() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if lastNitroResetDate != today {
            sentNitrosToday = ""
            lastNitroResetDate = today
        }
    }
}

// MARK: - 🔘 6. EngineStartButton
struct EngineStartButton: View {
    let action: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            SoundManager.shared.playEngineSound()
            action()
        }) {
            ZStack {
                Circle().fill(LinearGradient(colors: [.red, Color(red: 0.6, green: 0, blue: 0)], startPoint: .top, endPoint: .bottom)).frame(width: 80, height: 80).shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 2).frame(width: 70, height: 70)
                VStack(spacing: 2) {
                    Text("ENGINE").font(.system(size: 10, weight: .black, design: .monospaced))
                    Text("START").font(.system(size: 14, weight: .black, design: .monospaced))
                    Text("STOP").font(.system(size: 10, weight: .black, design: .monospaced)).opacity(0.3)
                }.foregroundColor(.white)
            }
        }
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { isAnimating = true } }
    }
}

// MARK: - ⚙️ 8. メニュー選択画面 (WorkoutSelectionView)
struct WorkoutSelectionView: View {
    @Binding var isRootActive: Bool
    @Binding var showFullWorkout: Bool 
    @Query private var routines: [WorkoutRoutine]
    @Environment(\.modelContext) private var context
    @AppStorage("driverName") private var driverName = "GUEST" 
    @State private var selectedRoutine: WorkoutRoutine? = nil
    
    @State private var navTarget: SelectionNavTarget? = nil
    @State private var quickStartEffect: Double = 0.0
    @State private var customEffect: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CarbonFiberBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SELECT MISSION").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(.cyan)
                        Text("Garage").font(.system(.largeTitle, design: .rounded).weight(.heavy)).foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: { isRootActive = false }) {
                        Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(.white.opacity(0.3))
                    }
                }.padding(.horizontal, 24).padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // ⚡️ QUICK START
                        Button {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            quickStartEffect = 1.0
                            withAnimation(.easeOut(duration: 0.5)) { quickStartEffect = 0.0 }
                            let timeString = Date().formatted(date: .omitted, time: .shortened)
                            let newRoutine = WorkoutRoutine(title: "クイックスタート (\(timeString))", themeColor: "cyan", ownerName: driverName)
                            selectedRoutine = newRoutine
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
                            SoundManager.shared.playSocketWrenchSound()
                            navTarget = .builder
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill").foregroundColor(.cyan).font(.title3)
                                Text("CUSTOM").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                                Spacer()
                            }
                            .padding().background(Color(white: 0.12)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.yellow).opacity(customEffect * 0.4))
                        
                        // 📋 REGISTERED
                        Text("REGISTERED BUILD").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(.gray).padding(.top, 10)
                        
                        if routines.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: 40)).foregroundColor(.gray.opacity(0.3))
                                Text("No Custom Routines").font(.subheadline.bold()).foregroundColor(.gray)
                            }.padding(.top, 40).frame(maxWidth: .infinity)
                        } else {
                            ForEach(routines) { routine in
                                RoutineCard(routine: routine, isSelected: selectedRoutine == routine, onEdit: {
                                    navTarget = .edit(routine)
                                })
                                    .contextMenu {
                                        Button { navTarget = .edit(routine) } label: { Label("Edit Routine", systemImage: "pencil") }
                                        Button(role: .destructive) {
                                            FirebaseManager.shared.deleteWorkoutRoutine(routine)
                                            context.delete(routine)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedRoutine = routine
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, selectedRoutine != nil ? 280 : 100)
                }
            }
            
            if let routine = selectedRoutine {
                WorkoutStartPedalView(
                    activeNeonColor: routine.themeColor.toColor,
                    isSelected: true,
                    onComplete: {
                        WorkoutSessionManager.shared.startSession(with: routine)
                        showFullWorkout = true
                        isRootActive = false
                    }
                )
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .navigationDestination(item: $navTarget) { target in
            switch target {
            case .builder:
                RoutineBuilderView()
            case .edit(let routine):
                RoutineBuilderView(routineToEdit: routine)
            case .detail(let routine):
                WorkoutDetailView(routine: routine, isRootActive: $isRootActive)
            }
        }
    }
}

// MARK: - 📋 12. RoutineCard (ネオンカラー連動版)
struct RoutineCard: View {
    let routine: WorkoutRoutine
    let isSelected: Bool
    var onEdit: (() -> Void)? = nil 
    
    private var routineColor: Color { routine.themeColor.toColor }
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle().fill(isSelected ? routineColor : Color.clear).frame(width: 4).cornerRadius(2)
            ZStack {
                Circle().fill(Color.white.opacity(0.05)).frame(width: 44, height: 44)
                Image(systemName: "engine.combustion.fill").font(.headline).foregroundColor(isSelected ? routineColor : .gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title).font(.system(.headline, design: .rounded).weight(.heavy)).foregroundColor(isSelected ? .white : Color(white: 0.8))
                Text(routine.exercises.first?.name != nil ? "\(routine.exercises.first!.name) など全\(routine.exercises.count)種目" : "種目なし").font(.caption.weight(.semibold)).foregroundColor(isSelected ? .gray : .gray.opacity(0.7))
            }
            Spacer()
            if isSelected {
                HStack(spacing: 16) {
                    Button { onEdit?() } label: { Image(systemName: "gearshape.fill").font(.title2).foregroundColor(.gray.opacity(0.8)) }.buttonStyle(.plain)
                    Image(systemName: "checkmark.circle.fill").foregroundColor(routineColor).font(.title2)
                }
            }
        }
        .padding(.vertical, 14).padding(.trailing, 16).background(isSelected ? routineColor.opacity(0.1) : Color(white: 0.1)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? routineColor.opacity(0.6) : Color.white.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - 🟢 13. BlinkingStatusView
struct BlinkingStatusView: View {
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @AppStorage("driverName") private var driverName = "GUEST"
    @State private var isBlinking = false
    
    var currentStatus: WorkoutStatus {
        if firebaseManager.liveTelemetries.contains(where: { $0.ownerName == driverName }) { return .training }
        if firebaseManager.leaderboardEntries.contains(where: { $0.ownerName == driverName && Calendar.current.isDateInToday($0.date) }) { return .finished }
        return .idle
    }
    
    var body: some View {
        HStack(spacing: 8){
            Circle()
                .fill(currentStatus.color)
                .frame(width: 8, height: 8)
                .opacity(currentStatus == .training ? (isBlinking ? 0.3 : 1.0) : 1.0)
            Text("STATUS \(currentStatus.rawValue.uppercased())")
                .font(.system(size: 11, weight: .bold,  design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
        }
        .onAppear{ withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)){ isBlinking = true } }
    }
}

// MARK: - 🛠️ 14. SettingsView (最新ハーフモーダル対応)
struct SettingsView: View {
    @AppStorage("isEngineSoundEnabled") var isEngineSoundEnabled = true
    @AppStorage("isShiftSoundEnabled") var isShiftSoundEnabled = true
    @AppStorage("isHapticEnabled") var isHapticEnabled = true
    @AppStorage("driverName") var driverName = "GUEST"
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("PROFILE").font(.custom("AvenirNext-Bold", size: 12))) {
                    HStack {
                        Label("ドライバー名", systemImage: "person.text.rectangle.fill")
                        Spacer()
                        TextField("名前を入力", text: $driverName).multilineTextAlignment(.trailing).foregroundColor(.cyan)
                    }
                }.listRowBackground(Color(white: 0.15)).foregroundColor(.white)
                
                Section(header: Text("SOUND & HAPTIC").font(.custom("AvenirNext-Bold", size: 12))) {
                    Toggle(isOn: $isEngineSoundEnabled) { Label("エンジン始動音", systemImage: "bolt.fill") }
                    Toggle(isOn: $isShiftSoundEnabled) { Label("シフト操作音", systemImage: "gauge.with.needle.fill") }
                    Toggle(isOn: $isHapticEnabled) { Label("振動フィードバック", systemImage: "waveform.path") }
                }.listRowBackground(Color(white: 0.15)).foregroundColor(.white).tint(.cyan)
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("SYSTEM SETTINGS").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("DONE") { dismiss() }.font(.headline).foregroundColor(.cyan) } }
        }
    }
}

// MARK: - 🏁 15. OnboardingView
struct OnboardingView: View {
    @Binding var driverName: String
    @State private var tempName: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CarbonFiberBackground().ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 80)).foregroundColor(.cyan)
                Text("DRIVER REGISTRATION").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                Text("コミュニティやテレメトリ同期に使用する\nドライバー名を入力してください。").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
                TextField("例: BRIAN", text: $tempName).font(.title2.bold()).foregroundColor(.cyan).multilineTextAlignment(.center).padding().background(Color(white: 0.15)).cornerRadius(12).padding(.horizontal, 40)
                Button {
                    if !tempName.isEmpty {
                        driverName = tempName
                        FirebaseManager.shared.registerDriver(name: tempName) // 💥 追加
                        FirebaseManager.shared.startListeningToNitroNotifications(for: tempName)
                        if AppSettings.shared.isHapticEnabled { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
                        dismiss()
                    }
                } label: {
                    Text("REGISTER").font(.headline.bold()).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(tempName.isEmpty ? Color.gray : Color.cyan).cornerRadius(12)
                }.disabled(tempName.isEmpty).padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - 🏆 20. ドライバーライセンス Enum
enum DriverLicense: String, CaseIterable {
    case beginner = "仮免許 (C級)"
    case classB = "国内B級"
    case classA = "国内A級"
    case intlB = "国際B級"
    case intlA = "国際A級"
    case superLicense = "スーパーライセンス"
    
    static func getLicense(for volume: Int) -> DriverLicense {
        switch volume {
        case 0..<5000: return .beginner
        case 5000..<20000: return .classB
        case 20000..<50000: return .classA
        case 50000..<100000: return .intlB
        case 100000..<200000: return .intlA
        default: return .superLicense
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .classB: return .green
        case .classA: return .blue
        case .intlB: return .purple
        case .intlA: return .orange
        case .superLicense: return .red
        }
    }
}
