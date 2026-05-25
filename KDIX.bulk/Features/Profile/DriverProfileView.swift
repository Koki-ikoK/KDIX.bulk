import SwiftUI
import SwiftData

struct DriverProfileView: View {
    let driverName: String
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var importedRoutineIds: Set<String> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CarbonFiberCanvasView().opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("DRIVER PROFILE")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        Image(systemName: "chevron.left").foregroundColor(.clear)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(Text(String(driverName.prefix(1))).font(.system(size: 40, weight: .black)).foregroundColor(.cyan))
                            .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                        
                        Text(driverName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        // 💥 追加：ライセンス表示
                        let driverVolume = firebaseManager.leaderboardEntries
                            .filter { $0.ownerName == driverName }
                            .reduce(0) { $0 + $1.totalVolume }
                        let license = DriverLicense.getLicense(for: driverVolume)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "medal.fill")
                                .foregroundColor(license.color)
                            Text(license.rawValue)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(license.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(license.color.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(license.color.opacity(0.3), lineWidth: 1))
                        
                        // 💥 追加：現在のステータス表示
                        if let liveInfo = firebaseManager.liveTelemetries.first(where: { $0.ownerName == driverName }) {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                        .symbolEffect(.pulse, options: .repeating)
                                    Text("LIVE IN MISSION").font(.system(size: 10, weight: .black)).foregroundColor(.green)
                                }
                                
                                Text(liveInfo.currentRoutineTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("NOW: \(liveInfo.currentExercise) (SET \(liveInfo.currentSet))")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.vertical, 20)
                .background(Color(white: 0.1))
                
                // Public Routines
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("PUBLIC MENUS")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        if firebaseManager.driverRoutines.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "lock.rectangle.stack")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("公開されているメニューはありません")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(firebaseManager.driverRoutines) { routine in
                                RoutineShareCard(routine: routine, isImported: importedRoutineIds.contains(routine.id ?? "")) {
                                    importRoutine(routine)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            firebaseManager.fetchPublicRoutines(for: driverName)
        }
    }

    private func importRoutine(_ cloudRoutine: CloudWorkoutRoutine) {
        let haptic = UIImpactFeedbackGenerator(style: .heavy)
        haptic.impactOccurred()

        let newRoutine = WorkoutRoutine(
            title: cloudRoutine.title + " (from \(cloudRoutine.ownerName))",
            themeColor: cloudRoutine.themeColor,
            ownerName: "GUEST", // 自分の名前はデフォルト
            isPublic: false // インポートしたものは最初は非公開
        )

        for cloudEx in cloudRoutine.exercises {
            let exercise = RoutineExercise(
                name: cloudEx.name,
                target: cloudEx.target,
                equipment: cloudEx.equipment,
                baseWeight: cloudEx.baseWeight,
                baseReps: cloudEx.baseReps,
                sets: cloudEx.sets,
                orderIndex: cloudEx.orderIndex
            )
            newRoutine.exercises.append(exercise)
        }

        context.insert(newRoutine)
        
        if let id = cloudRoutine.id {
            withAnimation {
                importedRoutineIds.insert(id)
            }
        }
    }
}

struct RoutineShareCard: View {
    let routine: CloudWorkoutRoutine
    let isImported: Bool
    let onImport: () -> Void
    
    var themeColor: Color {
        switch routine.themeColor {
        case "cyan": return .cyan
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .cyan
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(routine.title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: onImport) {
                    HStack(spacing: 4) {
                        Image(systemName: isImported ? "checkmark.circle.fill" : "square.and.arrow.down")
                        Text(isImported ? "IMPORTED" : "IMPORT")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(isImported ? .gray : themeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isImported ? Color.gray.opacity(0.1) : themeColor.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(isImported ? Color.gray.opacity(0.3) : themeColor.opacity(0.5), lineWidth: 1))
                }
                .disabled(isImported)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(routine.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).prefix(3), id: \.name) { ex in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(themeColor)
                        Text(ex.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(ex.baseWeight))kg x \(ex.baseReps) (\(ex.sets)sets)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                
                if routine.exercises.count > 3 {
                    Text("ほか \(routine.exercises.count - 3)種目")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.leading, 14)
                }
            }
            .padding(12)
            .background(Color(white: 0.15))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color(white: 0.12))
        .cornerRadius(20)
        .overlay(
            HStack {
                Rectangle().fill(themeColor).frame(width: 4)
                Spacer()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
