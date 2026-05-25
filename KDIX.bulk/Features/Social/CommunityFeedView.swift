import SwiftUI
import SwiftData

// MARK: - 📡 コミュニティフィード

struct FriendStatus: Identifiable {
    let id: String
    let name: String
    let status: WorkoutStatus
    let avatarColor: Color
    var receivedNitro: Int = 0 
    var currentRoutine: String? = nil 
    var currentActivity: String? = nil 
}

struct CommunityFeedView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("driverName") private var myDriverName = "GUEST"
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    struct DriverSelection: Identifiable, Hashable {
        let name: String
        var id: String { name }
    }
    @State private var selectedDriverForProfile: DriverSelection? = nil 
    @State private var nitroPoppingDrivers: Set<String> = [] 
    
    @AppStorage("sentNitrosToday") private var sentNitrosToday: String = "" 
    private var sentDriversList: Set<String> {
        Set(sentNitrosToday.components(separatedBy: ",").filter { !$0.isEmpty })
    }

    var sortedFriends: [FriendStatus] {
        var allDriverNames = Set(firebaseManager.allDrivers.map { $0.name })
        firebaseManager.leaderboardEntries.forEach { allDriverNames.insert($0.ownerName) }
        firebaseManager.liveTelemetries.forEach { allDriverNames.insert($0.ownerName) }
        let filteredNames = allDriverNames.filter({ $0 != myDriverName })
        
        let friends = filteredNames.map { name -> FriendStatus in
            let telemetry = firebaseManager.liveTelemetries.first(where: { $0.ownerName == name })
            var status: WorkoutStatus = .idle
            if telemetry != nil { status = .training }
            else if firebaseManager.leaderboardEntries.contains(where: { $0.ownerName == name && Calendar.current.isDateInToday($0.date) }) {
                status = .finished
            }
            return FriendStatus(id: name, name: name, status: status, avatarColor: .blue, receivedNitro: telemetry?.nitroCount ?? 0, currentRoutine: telemetry?.currentRoutineTitle, currentActivity: telemetry?.currentExercise)
        }
        return friends.sorted { a, b in
            let order: [WorkoutStatus: Int] = [.training: 0, .finished: 1, .idle: 2]
            return (order[a.status] ?? 3) < (order[b.status] ?? 3)
        }
    }
    
    var weeklyLeaderboard: [(name: String, volume: Int)] {
        var stats: [String: Int] = [:]
        var calendar = Calendar.current
        calendar.firstWeekday = 2 
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        for entry in firebaseManager.leaderboardEntries {
            if entry.date >= startOfWeek { stats[entry.ownerName, default: 0] += entry.totalVolume }
        }
        return stats.map { (name: $0.key, volume: $0.value) }.sorted { $0.volume > $1.volume }.prefix(5).map { ($0.name, $0.volume) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.1), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                CarbonFiberBackground().ignoresSafeArea()

                List {
                    // Pit Status
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                MyStatusAvatarView()
                                Divider().frame(height: 40).background(Color.white.opacity(0.2))
                                ForEach(sortedFriends) { friend in
                                    let hasSentToday = sentDriversList.contains(friend.name)
                                    StatusAvatarView(name: friend.name, status: friend.status, color: friend.avatarColor, currentActivity: friend.currentActivity, nitroCount: friend.receivedNitro)
                                        .overlay(nitroOverlay(for: friend.name))
                                        .scaleEffect(nitroPoppingDrivers.contains(friend.name) ? 1.2 : 1.0)
                                        .onTapGesture(count: 2) { if friend.status == .training && !hasSentToday { sendNitroWithEffect(to: friend.name) } }
                                        .onTapGesture { selectedDriverForProfile = DriverSelection(name: friend.name) }
                                        .opacity(hasSentToday ? 0.7 : 1.0)
                                }
                            }
                            .padding(.vertical, 10).padding(.horizontal, 20)
                        }
                        .listRowInsets(EdgeInsets()).listRowBackground(Color.gray.opacity(0.2))
                    } header: {
                        HStack {
                            Text("Pit Status").foregroundColor(.white).font(.headline.bold())
                            Spacer()
                            if !sortedFriends.filter({ $0.status == .training }).isEmpty {
                                Text("● \(sortedFriends.filter({ $0.status == .training }).count) LIVE").font(.caption2.bold()).foregroundColor(.green)
                            }
                        }.textCase(nil)
                    }

                    // Weekly Leaders
                    Section {
                        VStack(spacing: 12) {
                            ForEach(Array(weeklyLeaderboard.enumerated()), id: \.element.name) { index, item in
                                HStack {
                                    Text("\(index + 1)").font(.system(size: 16, weight: .black, design: .monospaced)).foregroundColor(index == 0 ? .yellow : (index == 1 ? .gray : .orange)).frame(width: 24)
                                    Text(item.name).font(.headline.bold()).foregroundColor(.white)
                                    Spacer()
                                    Text("\(item.volume) kg").font(.system(.subheadline, design: .monospaced).bold()).foregroundColor(.cyan)
                                }.padding(12).background(Color(white: 0.15)).cornerRadius(10)
                            }
                        }.padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "trophy.fill").foregroundColor(.yellow)
                            Text("Weekly Drivers").foregroundColor(.gray)
                            Spacer()
                            NavigationLink(destination: LeaderboardView()) {
                                Text("VIEW ALL").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.cyan)
                            }
                        }.font(.headline.weight(.bold)).textCase(nil)
                    }.listRowBackground(Color.clear)

                    // 💥 Mission Reports (強化版)
                    Section {
                        if firebaseManager.sharedReports.isEmpty {
                            Text("NO REPORTS YET").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.gray).frame(maxWidth: .infinity).padding()
                        } else {
                            ForEach(firebaseManager.sharedReports) { report in
                                MissionReportRow(report: report)
                                    .environment(\.modelContext, context) // 💥 ModelContextを渡す
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "bolt.horizontal.fill").foregroundColor(.orange)
                            Text("Mission Reports").foregroundColor(.gray)
                        }.font(.headline.weight(.bold)).textCase(nil)
                    }.listRowBackground(Color.white.opacity(0.05))
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
            .navigationTitle("Community")
            .onAppear { firebaseManager.startListeningToFeed() }
            .onDisappear { firebaseManager.stopListening() }
            .navigationDestination(item: $selectedDriverForProfile) { selection in DriverProfileView(driverName: selection.name) }
        }
    }
    
    @ViewBuilder
    private func nitroOverlay(for name: String) -> some View {
        if nitroPoppingDrivers.contains(name) {
            Text("⚡️").font(.system(size: 40, weight: .black)).foregroundColor(.yellow).shadow(color: .orange, radius: 10)
                .transition(.asymmetric(insertion: .scale(scale: 0.1).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity))).zIndex(10)
        }
    }

    private func sendNitroWithEffect(to driverName: String) {
        let impact = UIImpactFeedbackGenerator(style: .heavy); impact.impactOccurred()
        FirebaseManager.shared.sendNitroToLiveUser(ownerName: driverName, senderName: myDriverName)
        var list = sentDriversList; let _ = list.insert(driverName); sentNitrosToday = list.joined(separator: ",")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { let _ = nitroPoppingDrivers.insert(driverName) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation(.easeOut(duration: 0.3)) { let _ = nitroPoppingDrivers.remove(driverName) } }
    }
}

// 💥 修正：ミッションレポートの行（縦長画像対応）
struct MissionReportRow: View {
    let report: SharedMissionReport
    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false
    @State private var importSuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle().fill(Color(hex: report.themeColor).opacity(0.2)).frame(width: 32, height: 32)
                    .overlay(Text(String(report.ownerName.prefix(1))).font(.caption.bold()).foregroundColor(Color(hex: report.themeColor)))
                VStack(alignment: .leading, spacing: 0) {
                    Text(report.ownerName).font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(.white)
                    Text(report.date.formatted(.dateTime.month().day().hour().minute())).font(.system(size: 8)).foregroundColor(.gray)
                }
                Spacer()
                // 💥 修正：インポート可能かどうかの表示
                if let rid = report.routineID {
                    if report.isRoutinePublic == true {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            importRoutine(id: rid)
                        } label: {
                            HStack(spacing: 4) {
                                if isImporting {
                                    ProgressView().tint(.black).scaleEffect(0.7)
                                } else {
                                    Image(systemName: importSuccess ? "checkmark" : "plus.square.fill.on.square.fill")
                                    Text(importSuccess ? "IMPORTED" : "IMPORT").font(.system(size: 10, weight: .black))
                                }
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(importSuccess ? Color.green : Color.cyan)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.borderless)
                        .disabled(isImporting || importSuccess)
                    } else {
                        // 💥 プライベートメニューの場合の表示
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                            Text("PRIVATE").font(.system(size: 10, weight: .black))
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(6)
                    }
                }
            }
            
            // 💥 修正：縦長画像表示（実機の比率そのまま）
            if let base64 = report.photoBase64, let data = Data(base64Encoded: base64), let uiImage = UIImage(data: data) {
                let screenBounds = UIScreen.main.bounds
                let aspectRatio = screenBounds.height / screenBounds.width
                
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 60) // 左右パディング分を引く
                    .frame(height: (UIScreen.main.bounds.width - 60) * aspectRatio)
                    .background(Color.black)
                    .cornerRadius(12)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(report.routineName).font(.headline.bold()).foregroundColor(.white)
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("MASS").font(.system(size: 8, weight: .bold)).foregroundColor(.gray)
                        Text("\(report.totalVolume) KG").font(.system(size: 16, weight: .black, design: .monospaced)).foregroundColor(Color(hex: report.themeColor))
                    }
                    VStack(alignment: .leading) {
                        Text("TIME").font(.system(size: 8, weight: .bold)).foregroundColor(.gray)
                        Text(report.totalTime).font(.system(size: 16, weight: .black, design: .monospaced)).foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    // 💥 修正：ルーティンインポートロジック
    private func importRoutine(id: String) {
        isImporting = true
        FirebaseManager.shared.fetchRoutine(id: id) { cloudRoutine in
            guard let cr = cloudRoutine else {
                isImporting = false
                return
            }
            
            // SwiftDataに変換して保存
            let newRoutine = WorkoutRoutine(
                title: "\(cr.title) (Imported)",
                themeColor: cr.themeColor,
                ownerName: cr.ownerName,
                isPublic: false
            )
            
            for ex in cr.exercises {
                let newEx = RoutineExercise(
                    name: ex.name, target: ex.target, equipment: ex.equipment,
                    baseWeight: ex.baseWeight, baseReps: ex.baseReps, sets: ex.sets, orderIndex: ex.orderIndex
                )
                newRoutine.exercises.append(newEx)
            }
            
            modelContext.insert(newRoutine)
            
            withAnimation {
                isImporting = false
                importSuccess = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

struct MyStatusAvatarView: View {
    @AppStorage("driverName") private var myDriverName = "GUEST"
    @ObservedObject var firebaseManager = FirebaseManager.shared
    var body: some View {
        let isLive = firebaseManager.liveTelemetries.contains(where: { $0.ownerName == myDriverName })
        let isDone = firebaseManager.leaderboardEntries.contains(where: { $0.ownerName == myDriverName && Calendar.current.isDateInToday($0.date) })
        StatusAvatarView(name: myDriverName, status: isLive ? .training : (isDone ? .finished : .idle), color: .cyan)
    }
}

struct StatusAvatarView: View {
    let name: String; let status: WorkoutStatus; let color: Color; var currentActivity: String? = nil; var nitroCount: Int = 0
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle().fill(color.opacity(0.2)).frame(width: 60, height: 60).overlay(Text(String(name.prefix(1))).font(.title2.bold()).foregroundColor(color))
                if nitroCount > 0 {
                    Text("⚡️\(nitroCount)").font(.system(size: 10, weight: .black)).foregroundColor(.black).padding(.horizontal, 4).padding(.vertical, 2).background(Color.yellow).clipShape(Capsule()).offset(x: 5, y: -5)
                }
                ZStack {
                    Circle().fill(Color(UIColor.systemGroupedBackground)).frame(width: 20, height: 20)
                    Image(systemName: "circle.fill").resizable().foregroundColor(status == .training ? .green : .gray.opacity(0.5)).frame(width: 14, height: 14)
                }
            }
            VStack(spacing: 2) {
                Text(name).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.primary)
                Text(status == .training ? (currentActivity ?? "LIVE") : (status == .finished ? "DONE" : "IDLE")).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(status.color)
            }
        }.frame(width: 80)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
