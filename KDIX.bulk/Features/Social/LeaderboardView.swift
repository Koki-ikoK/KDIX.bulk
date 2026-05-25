import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    @AppStorage("driverName") private var myDriverName = "GUEST"
    // 💥 変更：新データ構造に対応
    var rankingData: [(name: String, totalVolume: Int, workoutCount: Int)] {
        var userStats: [String: (volume: Int, count: Int)] = [:]

        for entry in firebaseManager.leaderboardEntries {
            let current = userStats[entry.ownerName, default: (0, 0)]
            userStats[entry.ownerName] = (current.volume + entry.totalVolume, current.count + 1)
        }

        return userStats.map { (name: $0.key, totalVolume: $0.value.volume, workoutCount: $0.value.count) }
            .sorted { $0.totalVolume > $1.totalVolume }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CarbonFiberCanvasView().opacity(0.4).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if firebaseManager.leaderboardEntries.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.cyan)
                        Text("CALCULATING RANKINGS...")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(rankingData.enumerated()), id: \.element.name) { index, item in
                                rankingRow(rank: index + 1, data: item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            firebaseManager.startListeningToFeed()
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Text("WORLD LEADERBOARD")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                Spacer()
                Image(systemName: "chevron.left").foregroundColor(.clear)
            }
            .padding(.horizontal)
            
            HStack(spacing: 30) {
                VStack {
                    Text("TOTAL USERS").font(.caption2).foregroundColor(.gray)
                    Text("\(rankingData.count)").font(.system(.title3, design: .monospaced).bold()).foregroundColor(.white)
                }
                VStack {
                    Text("TOTAL VOLUME").font(.caption2).foregroundColor(.gray)
                    let total = rankingData.reduce(0) { $0 + $1.totalVolume }
                    Text("\(total / 1000)t").font(.system(.title3, design: .monospaced).bold()).foregroundColor(.cyan)
                }
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .background(Color(white: 0.1).ignoresSafeArea())
    }
    
    private func rankingRow(rank: Int, data: (name: String, totalVolume: Int, workoutCount: Int)) -> some View {
        let isMe = data.name == myDriverName
        
        return HStack(spacing: 16) {
            // Rank Number
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor(rank))
                        .frame(width: 32, height: 32)
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(width: 32)
                }
            }
            
            // Driver Icon
            Circle()
                .fill(rank == 1 ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(Text(String(data.name.prefix(1))).font(.headline.bold()).foregroundColor(rank == 1 ? .yellow : .white))
                .overlay(Circle().stroke(isMe ? Color.cyan : Color.clear, lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(data.name)
                    .font(.headline.bold())
                    .foregroundColor(isMe ? .cyan : .white)
                Text("\(data.workoutCount) WORKOUTS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(data.totalVolume)")
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundColor(.white)
                Text("KG")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.cyan)
            }
        }
        .padding()
        .background(isMe ? Color.cyan.opacity(0.1) : Color(white: 0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isMe ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }
}
