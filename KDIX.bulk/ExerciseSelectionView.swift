import SwiftUI
import SwiftData

// 選択した種目を一時保存するための構造体
struct DraftExercise: Identifiable {
    let id = UUID()
    var master: ExerciseMaster
    var weight: Double
    var reps: Int
    var sets: Int
}

struct ExerciseSelectionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [DraftExercise]
    
    @Query private var customExercises: [CustomExercise]
    @State private var searchText = ""
    
    // 🌟 新規追加：シートの表示と、部位・器具の設定用変数
    @State private var showingAddSheet = false
    @State private var selectedTarget: MuscleGroup = .chest
    @State private var selectedEquipment: Equipment = .machine
    
    // マスター種目とカスタム種目を合体させた「最強のリスト」
    var allAvailableExercises: [ExerciseMaster] {
        let masters = allMasterExercises
        let customs = customExercises.compactMap { custom in
            // 保存されている文字列から部位と器具のカテゴリ（Enum）に変換
            let targetEnum = MuscleGroup(rawValue: custom.target) ?? .core
            let equipEnum = Equipment(rawValue: custom.equipment) ?? .other
            return ExerciseMaster(name: custom.name, target: targetEnum, equipment: equipEnum, defaultWeight: custom.defaultWeight, defaultReps: custom.defaultReps)
        }
        return masters + customs
    }
    
    // 検索結果の絞り込み
    var searchResults: [ExerciseMaster] {
        if searchText.isEmpty {
            return allAvailableExercises
        } else {
            return allAvailableExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 🔍 検索窓
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("種目を検索... (例: ベンチプレス)", text: $searchText)
                            .submitLabel(.search)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding()
                    
                    List {
                        // 🌟 検索して見つからなかったら「自動生成ボタン」を出す
                        if searchResults.isEmpty && !searchText.isEmpty {
                            Section {
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    // 👇 シートを表示して部位と器具を選ばせる！
                                    showingAddSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.blue)
                                        Text("「\(searchText)」を新しく登録する")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 8)
                                }
                            } footer: {
                                Text("部位と器具を設定して登録します。")
                            }
                        }
                        
                        // 検索結果のリスト表示
                        ForEach(searchResults) { ex in
                            Button {
                                let impact = UISelectionFeedbackGenerator()
                                impact.selectionChanged()
                                let newDraft = DraftExercise(master: ex, weight: ex.defaultWeight, reps: ex.defaultReps, sets: 3)
                                selectedExercises.append(newDraft)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ex.name).font(.headline).foregroundColor(.primary)
                                        Text("\(ex.target.rawValue) / \(ex.equipment.rawValue)").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus").foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("種目を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            // 🌟 ハーフシート（画面の半分だけ下から出てくる）の設定画面
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section("種目名") {
                            Text(searchText).font(.headline.bold())
                        }
                        Section("詳細設定") {
                            Picker("鍛える部位", selection: $selectedTarget) {
                                ForEach(MuscleGroup.allCases) { group in
                                    Text(group.rawValue).tag(group)
                                }
                            }
                            Picker("使用する器具", selection: $selectedEquipment) {
                                ForEach(Equipment.allCases) { eq in
                                    Text(eq.rawValue).tag(eq)
                                }
                            }
                        }
                    }
                    .navigationTitle("新規種目の登録")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") { showingAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("登録") {
                                // 設定した部位と器具を渡して保存！
                                addNewCustomExercise(name: searchText, target: selectedTarget, equipment: selectedEquipment)
                                showingAddSheet = false
                            }.font(.headline)
                        }
                    }
                }
                .presentationDetents([.medium]) // これが「画面の半分だけ出す」魔法のコード！
            }
        }
    }
    
    // 🌟 カスタム種目をデータベースに保存する関数（部位と器具に対応）
    func addNewCustomExercise(name: String, target: MuscleGroup, equipment: Equipment) {
        let newExercise = CustomExercise(name: name, target: target.rawValue, equipment: equipment.rawValue)
        context.insert(newExercise)
        
        let draftMaster = ExerciseMaster(name: name, target: target, equipment: equipment, defaultWeight: 20.0, defaultReps: 10)
        let newDraft = DraftExercise(master: draftMaster, weight: 20.0, reps: 10, sets: 3)
        selectedExercises.append(newDraft)
        
        dismiss()
    }
}
