import SwiftUI
import SwiftData

// 選択した種目を一時保存するための構造体
struct DraftExercise: Identifiable, Equatable {
    let id = UUID()
    var master: ExerciseMaster
    var weight: Double
    var reps: Int
    var sets: Int
    var isExpanded: Bool = false // 🌟 ルーチンビルダーでの詳細編集用
    
    static func == (lhs: DraftExercise, rhs: DraftExercise) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExerciseSelectionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [DraftExercise]
    
    let activeNeonColor: Color // 親Viewのテーマカラーを引き継ぐ
    
    @Query private var customExercises: [CustomExercise]
    @State private var searchText = ""
    @State private var selectedFilter: MuscleGroup = .chest
    @State private var tempSelectedIDs: [UUID] = [] // 🌟 順番を保持するために配列にする
    
    // カスタム種目作成用
    @State private var showingAddSheet = false
    @State private var selectedTarget: MuscleGroup = .chest
    @State private var selectedEquipment: Equipment = .machine
    
    var allAvailableExercises: [ExerciseMaster] {
        let masters = allMasterExercises
        let customs = customExercises.compactMap { custom in
            let targetEnum = MuscleGroup(rawValue: custom.target) ?? .core
            let equipEnum = Equipment(rawValue: custom.equipment) ?? .other
            return ExerciseMaster(name: custom.name, target: targetEnum, equipment: equipEnum, defaultWeight: custom.defaultWeight, defaultReps: custom.defaultReps)
        }
        return masters + customs
    }
    
    var searchResults: [ExerciseMaster] {
        if searchText.isEmpty {
            return allAvailableExercises.filter { $0.target == selectedFilter }
        } else {
            return allAvailableExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 💥 ワイスピ風ブラック背景
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 🔍 検索窓 (ネオンアクセント)
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(searchText.isEmpty ? .gray : activeNeonColor)
                        TextField("SEARCH PARTS...", text: $searchText)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button(action: { withAnimation { searchText = "" } }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(searchText.isEmpty ? Color.clear : activeNeonColor, lineWidth: 2))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                    // 部位フィルター
                    if searchText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(MuscleGroup.allCases) { group in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = group
                                        }
                                    } label: {
                                        Text(group.rawValue)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedFilter == group ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedFilter == group ? activeNeonColor : Color(red: 0.15, green: 0.15, blue: 0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        }
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if searchResults.isEmpty && !searchText.isEmpty {
                                customPartCreatorPanel
                            } else {
                                ForEach(searchResults) { ex in
                                    let orderIndex = tempSelectedIDs.firstIndex(of: ex.id)
                                    let isSelected = orderIndex != nil
                                    
                                    Button {
                                        toggleSelection(for: ex)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(ex.name).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                                                Text(ex.equipment.rawValue).font(.caption.weight(.bold)).foregroundColor(.gray)
                                            }
                                            Spacer()
                                            
                                            if let idx = orderIndex {
                                                Text("NO.\(idx + 1)")
                                                    .font(.system(.headline, design: .monospaced).weight(.black))
                                                    .foregroundColor(activeNeonColor)
                                            } else {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(.gray.opacity(0.3))
                                                    .font(.title2)
                                            }
                                        }
                                        .padding()
                                        .background(isSelected ? activeNeonColor.opacity(0.1) : Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? activeNeonColor : Color.clear, lineWidth: 2))
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("PARTS CATALOG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CANCEL") {
                        // 今回選択した分を戻す（親ViewのselectedExercisesに影響させないために本来はコピーを持つべきだが、要件に合わせて調整）
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("INSTALL (\(tempSelectedIDs.count))") {
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundColor(tempSelectedIDs.isEmpty ? .gray : activeNeonColor)
                    .disabled(tempSelectedIDs.isEmpty)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                customExerciseAddSheet
            }
        }
    }
    
    private func toggleSelection(for ex: ExerciseMaster) {
        let impact = UISelectionFeedbackGenerator()
        impact.selectionChanged()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let idx = tempSelectedIDs.firstIndex(of: ex.id) {
                tempSelectedIDs.remove(at: idx)
                selectedExercises.removeAll(where: { $0.master.id == ex.id })
            } else {
                tempSelectedIDs.append(ex.id)
                let newDraft = DraftExercise(master: ex, weight: ex.defaultWeight, reps: ex.defaultReps, sets: 3)
                selectedExercises.append(newDraft)
            }
        }
    }
    
    // MARK: - カスタム種目作成パネル (インライン表示)
    private var customPartCreatorPanel: some View {
        Button {
            showingAddSheet = true
        } label: {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill").foregroundColor(.yellow)
                    Text("CREATE CUSTOM PART").font(.system(.caption, design: .monospaced).weight(.bold)).foregroundColor(.yellow)
                    Spacer()
                }
                Text(searchText).font(.system(.headline, design: .rounded).weight(.black)).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                Text("TAP TO CONFIGURE").font(.caption.bold()).foregroundColor(.gray)
            }
            .padding()
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.5), lineWidth: 1))
        }
    }
    
    // MARK: - 新規登録用ハーフシート
    private var customExerciseAddSheet: some View {
        NavigationStack {
            Form {
                Section("PART NAME") {
                    Text(searchText).font(.headline.bold())
                }
                Section("SPECIFICATIONS") {
                    Picker("TARGET AREA", selection: $selectedTarget) {
                        ForEach(MuscleGroup.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("EQUIPMENT", selection: $selectedEquipment) {
                        ForEach(Equipment.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            .navigationTitle("REGISTER CUSTOM PART")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("CANCEL") { showingAddSheet = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("REGISTER") {
                        addNewCustomExercise(name: searchText, target: selectedTarget, equipment: selectedEquipment)
                        showingAddSheet = false
                    }.font(.headline).foregroundColor(activeNeonColor)
                }
            }
            .presentationDetents([.medium])
            .preferredColorScheme(.dark)
        }
    }
    
    func addNewCustomExercise(name: String, target: MuscleGroup, equipment: Equipment) {
        let newExercise = CustomExercise(name: name, target: target.rawValue, equipment: equipment.rawValue)
        context.insert(newExercise)
        
        let draftMaster = ExerciseMaster(name: name, target: target, equipment: equipment, defaultWeight: 20.0, defaultReps: 10)
        toggleSelection(for: draftMaster)
    }
}
