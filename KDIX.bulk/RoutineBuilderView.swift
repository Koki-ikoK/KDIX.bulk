import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AudioToolbox

// MARK: - 1. データモデル
struct DraftPart: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var equipment: String
    var weight: Double
    var reps: Int
    var sets: Int
    var isExpanded: Bool = false
}

// MARK: - 2. ドラッグ＆ドロップ Delegate
struct PartDropDelegate: DropDelegate {
    let item: DraftPart
    @Binding var listData: [DraftPart]
    @Binding var draggedID: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedID = draggedID, draggedID != item.id else { return }
        let from = listData.firstIndex(where: { $0.id == draggedID })
        let to = listData.firstIndex(where: { $0.id == item.id })
        if let from = from, let to = to, from != to {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                listData.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

// MARK: - 3. Liquid Glass (信号機・ソリッド版)
struct LiquidGlassCircle: View {
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // 底面発光
            Circle()
                .fill(color.opacity(isSelected ? 0.6 : 0.1))
                .blur(radius: isSelected ? 15 : 0)
            
            // レンズ本体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color.opacity(1.0), Color(white: 0.15)]),
                        center: .center, startRadius: 0, endRadius: 22
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                .overlay(
                    Circle().stroke(Color.black.opacity(0.4), lineWidth: 4).blur(radius: 2).offset(x: 2, y: 2).mask(Circle())
                )
                .overlay(
                    VStack {
                        Ellipse()
                            .fill(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 18, height: 8).padding(.top, 6).rotationEffect(.degrees(-10))
                        Spacer()
                    }
                )
            
            // ベゼル
            Circle()
                .stroke(isSelected ? Color.white : Color(white: 0.2), lineWidth: isSelected ? 3 : 1)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: isSelected ? color : .clear, radius: 8)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - 4. マザーボード風背景 (超軽量Canvas)
struct MotherboardCanvasView: View {
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 40
            let style = StrokeStyle(lineWidth: 0.5)
            
            for x in stride(from: 0, to: size.width, by: step) {
                for y in stride(from: 0, to: size.height, by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    
                    if (Int(x + y) / Int(step)) % 3 == 0 {
                        path.addLine(to: CGPoint(x: x + step * 0.5, y: y + step * 0.5))
                        path.addLine(to: CGPoint(x: x + step, y: y + step * 0.5))
                        let rect = CGRect(x: x + step - 2, y: y + step * 0.5 - 2, width: 4, height: 4)
                        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.3)))
                    }
                    context.stroke(path, with: .color(color.opacity(0.1)), style: style)
                }
            }
        }
        .drawingGroup()
    }
}

// MARK: - 5. カーボンファイバー背景 (超軽量Canvas)
struct CarbonFiberCanvasView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1000)) { _ in
            Canvas { context, size in
                let tileSize: CGFloat = 10
                let rows = Int(size.height / tileSize) + 1
                let cols = Int(size.width / tileSize) + 1
                
                for r in 0..<rows {
                    for c in 0..<cols {
                        let x = CGFloat(c) * tileSize
                        let y = CGFloat(r) * tileSize
                        let isAlt = (r + c) % 2 == 0
                        
                        let rect = CGRect(x: x, y: y, width: tileSize, height: tileSize)
                        context.fill(Path(rect), with: .color(isAlt ? Color(white: 0.08) : Color(white: 0.12)))
                        
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + tileSize, y: y + tileSize))
                        context.stroke(path, with: .color(Color.black.opacity(0.3)), lineWidth: 1)
                    }
                }
            }
        }
        .drawingGroup()
    }
}

// MARK: - 6. メインView
struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var routineToEdit: WorkoutRoutine?
    
    @State private var routineName: String = ""
    @State private var selectedColor: String = "cyan"
    @State private var partsList: [DraftPart] = []
    
    @State private var isShowingPartSelector = false
    @State private var selectedFilter: MuscleGroup = .chest
    @State private var isPulsing: Bool = false
    @State private var searchText: String = ""
    
    let equipmentOptions: [String] = ["バーベル", "ダンベル", "マシン", "ケーブル", "自重", "その他"]
    @State private var selectedCustomEquipment: String = "ダンベル"
    
    @State private var draggedID: UUID? = nil
    
    let neonColors: [(name: String, color: Color)] = [
        ("cyan", .cyan), ("blue", .blue), ("green", .green),
        ("yellow", .yellow), ("orange", .orange), ("red", .red), ("purple", .purple)
    ]
    
    private var activeNeonColor: Color {
        neonColors.first(where: { $0.name == selectedColor })?.color ?? .cyan
    }
    
    let weightOptions: [Double] = Array(stride(from: 0.0, through: 200.0, by: 0.5))
    let repsOptions: [Int] = Array(1...50)
    let setsOptions: [Int] = Array(1...10)

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景（Canvas製カーボンを適用）
            Color.black.ignoresSafeArea()
            CarbonFiberCanvasView().opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 0) {
                customNavBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        buildNameSection
                        neonAccentSection
                        partsListSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
                .onDrop(of: [UTType.plainText], isTargeted: nil) { _ in draggedID = nil; return true }
            }
            
            installButtonSection
        }
        .onDrop(of: [UTType.plainText], isTargeted: nil) { _ in draggedID = nil; return true }
        .sheet(isPresented: $isShowingPartSelector) {
            partsCatalogSheet
        }
        .onAppear {
            if let routine = routineToEdit {
                routineName = routine.title; selectedColor = routine.themeColor
            }
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) { isPulsing = true }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - サブView部品
    
    private var neonAccentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NEON ACCENT").font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(.gray)
                Spacer()
                Text("LIQUID GLASS").font(.system(size: 8, weight: .bold)).foregroundColor(.gray.opacity(0.5))
            }
            
            // 👇 横スクロール復活（はみ出し防止）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(neonColors, id: \.name) { item in
                        LiquidGlassCircle(color: item.color, isSelected: selectedColor == item.name)
                            .padding(.vertical, 10)
                            .onTapGesture {
                                let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { selectedColor = item.name }
                            }
                    }
                }
                .padding(.horizontal, 10)
            }
            .background(Color.white.opacity(0.03)).clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    private var partsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("PARTS LIST").font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(.gray)
                Spacer()
                Text("\(partsList.count) PARTS INSTALLED").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(activeNeonColor.opacity(0.8))
            }
            
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()
                isShowingPartSelector = true; searchText = ""
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.square.fill.on.square.fill").font(.title3)
                    Text("INSTALL NEW PART").font(.system(size: 14, weight: .black, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                .foregroundColor(activeNeonColor).padding().frame(maxWidth: .infinity)
                .background(activeNeonColor.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(activeNeonColor.opacity(0.5), lineWidth: 1))
            }
            
            if partsList.isEmpty {
                // 👇 マザーボード背景適用
                ZStack {
                    MotherboardCanvasView(color: .white).opacity(0.5)
                    VStack(spacing: 12) {
                        Image(systemName: "cpu").font(.system(size: 32)).foregroundColor(.gray)
                        Text("No Parts Installed").font(.subheadline.weight(.semibold)).foregroundColor(.gray)
                    }
                }
                .frame(height: 180).background(Color(white: 0.1)).clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(activeNeonColor.opacity(0.2), lineWidth: 1))
            } else {
                ForEach(partsList, id: \.id) { part in
                    partRowView(for: part)
                        .opacity(draggedID == part.id ? 0.3 : 1.0)
                        .onDrag {
                            let impact = UIImpactFeedbackGenerator(style: .heavy); impact.impactOccurred()
                            self.draggedID = part.id; return NSItemProvider(object: part.id.uuidString as NSString)
                        }
                        .onDrop(of: [UTType.plainText], delegate: PartDropDelegate(item: part, listData: $partsList, draggedID: $draggedID))
                }
            }
        }
    }
    
    private func partRowView(for part: DraftPart) -> some View {
        let index = partsList.firstIndex(where: { $0.id == part.id }) ?? 0
        let partBinding = Binding<DraftPart>(
            get: { index < partsList.count ? partsList[index] : part },
            set: { if index < partsList.count { partsList[index] = $0 } }
        )
        
        return VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("\(index + 1)").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(.gray).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(partBinding.wrappedValue.name).font(.system(.body, design: .rounded).weight(.bold)).foregroundColor(.white).lineLimit(1)
                    if !partBinding.wrappedValue.isExpanded {
                        HStack(spacing: 0) {
                            dashboardValue(value: String(format: "%.1f", partBinding.wrappedValue.weight), unit: "kg")
                            dashDivider
                            dashboardValue(value: "\(partBinding.wrappedValue.reps)", unit: "reps")
                            dashDivider
                            dashboardValue(value: "\(partBinding.wrappedValue.sets)", unit: "sets")
                        }
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "line.3.horizontal").foregroundColor(.gray.opacity(0.3)).font(.system(size: 14))
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { partBinding.wrappedValue.isExpanded.toggle() } }) {
                        Image(systemName: "slider.horizontal.3").foregroundColor(partBinding.wrappedValue.isExpanded ? activeNeonColor : .gray).font(.system(size: 16))
                    }
                    Button(action: { withAnimation { _ = partsList.remove(at: index) } }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.1)).font(.system(size: 16))
                    }
                }
            }
            .padding().background(Color(red: 0.15, green: 0.15, blue: 0.15))
            
            if partBinding.wrappedValue.isExpanded {
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("WEIGHT (kg)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        Picker("Weight", selection: partBinding.weight) { ForEach(weightOptions, id: \.self) { w in Text(String(format: "%.1f", w)).tag(w) } }.pickerStyle(.wheel)
                    }.frame(maxWidth: .infinity)
                    VStack(spacing: 4) {
                        Text("REPS").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        Picker("Reps", selection: partBinding.reps) { ForEach(repsOptions, id: \.self) { r in Text("\(r)").tag(r) } }.pickerStyle(.wheel)
                    }.frame(maxWidth: .infinity)
                    VStack(spacing: 4) {
                        Text("SETS").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        Picker("Sets", selection: partBinding.sets) { ForEach(setsOptions, id: \.self) { s in Text("\(s)").tag(s) } }.pickerStyle(.wheel)
                    }.frame(maxWidth: .infinity)
                }
                .frame(height: 120).padding(.bottom, 8).background(Color(red: 0.12, green: 0.12, blue: 0.12)).environment(\.colorScheme, .dark)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay( HStack { Rectangle().fill(activeNeonColor).frame(width: 4); Spacer() } )
    }
    
    // MARK: - カタログ（シート）
        private var partsCatalogSheet: some View {
            NavigationStack {
                ZStack(alignment: .top) {
                    Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass").foregroundColor(searchText.isEmpty ? .gray : activeNeonColor).font(.title3)
                            TextField("SEARCH PARTS...", text: $searchText).font(.system(.headline, design: .monospaced)).foregroundColor(.white).autocorrectionDisabled()
                            if !searchText.isEmpty { Button(action: { withAnimation { searchText = "" } }) { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                        }
                        .padding().background(Color(red: 0.15, green: 0.15, blue: 0.15)).clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(searchText.isEmpty ? Color.clear : activeNeonColor, lineWidth: 2))
                        .padding(.horizontal, 20).padding(.vertical, 16).background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                        if searchText.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(MuscleGroup.allCases) { group in
                                        Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedFilter = group }
                                        } label: {
                                            Text(group.rawValue).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(selectedFilter == group ? .black : .gray)
                                                .padding(.horizontal, 16).padding(.vertical, 10).background(selectedFilter == group ? activeNeonColor : Color(red: 0.15, green: 0.15, blue: 0.15)).clipShape(Capsule())
                                        }
                                    }
                                }.padding(.horizontal, 20).padding(.bottom, 12)
                            }.background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        }
                        
                        ScrollView {
                            VStack(spacing: 12.0) {
                                let filteredExercises = searchText.isEmpty
                                    ? allMasterExercises.filter { $0.target == selectedFilter }
                                    : allMasterExercises.filter { $0.name.localizedStandardContains(searchText) }
                                
                                if filteredExercises.isEmpty && !searchText.isEmpty {
                                    customPartCreatorPanel
                                } else {
                                    ForEach(filteredExercises) { exercise in
                                        let orderIndex = partsList.firstIndex(where: { $0.name == exercise.name })
                                        let isSelected = orderIndex != nil
                                        Button { withAnimation {
                                            if let idx = orderIndex {
                                                _ = partsList.remove(at: idx)
                                            } else {
                                                // 👇 修正：insert(at: 0) をやめて append に変更！
                                                partsList.append(DraftPart(name: exercise.name, equipment: exercise.equipment.rawValue, weight: exercise.defaultWeight, reps: exercise.defaultReps, sets: 3))
                                            }
                                        }} label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(exercise.name).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                                                    Text(exercise.equipment.rawValue).font(.caption.weight(.bold)).foregroundColor(.gray)
                                                }
                                                Spacer()
                                                if let idx = orderIndex { Text("NO.\(idx + 1)").font(.system(.headline, design: .monospaced).weight(.black)).foregroundColor(activeNeonColor) }
                                                else { Image(systemName: "plus.circle.fill").foregroundColor(.gray.opacity(0.3)).font(.title2) }
                                            }
                                            .padding().background(isSelected ? activeNeonColor.opacity(0.1) : Color(red: 0.15, green: 0.15, blue: 0.15)).clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? activeNeonColor : Color.clear, lineWidth: 2))
                                        }
                                    }
                                }
                            }.padding(20).padding(.bottom, 40)
                        }
                    }
                }
                .navigationTitle("PARTS CATALOG").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("CLOSE") { isShowingPartSelector = false }.foregroundColor(activeNeonColor) } }
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        
        // MARK: - カスタム種目作成パネル
        private var customPartCreatorPanel: some View {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill").foregroundColor(.yellow)
                    Text("CREATE CUSTOM PART").font(.system(.caption, design: .monospaced).weight(.bold)).foregroundColor(.yellow)
                    Spacer()
                }
                Text(searchText).font(.system(.headline, design: .rounded).weight(.black)).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("EQUIPMENT").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    Spacer()
                    Menu {
                        ForEach(equipmentOptions, id: \.self) { eq in Button(eq) { selectedCustomEquipment = eq } }
                    } label: {
                        HStack {
                            Text(selectedCustomEquipment).font(.subheadline.bold()).foregroundColor(.white)
                            Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.yellow)
                        }.padding(8).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                Button { withAnimation {
                    // 👇 修正：こちらも insert(at: 0) をやめて append に変更！
                    partsList.append(DraftPart(name: searchText, equipment: selectedCustomEquipment, weight: 20, reps: 10, sets: 3))
                    searchText = ""
                }} label: {
                    Text("INSTALL NEW PART").font(.headline.bold()).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(Color.yellow).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }.padding().background(Color(red: 0.15, green: 0.15, blue: 0.15)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow, style: StrokeStyle(lineWidth: 2, dash: [6])))
        }
    
    
    // MARK: - その他ヘルパー
    
    private func dashboardValue(value: String, unit: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(value).font(.system(size: 14, weight: .black, design: .monospaced)).foregroundColor(activeNeonColor)
            Text(unit).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.gray)
        }.fixedSize()
    }
    
    private var dashDivider: some View {
        Text("|").font(.system(size: 10)).foregroundColor(Color.white.opacity(0.1)).padding(.horizontal, 10)
    }

    private var buildNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BUILD NAME").font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(.gray)
            TextField("例: 爆速チェストデイ", text: $routineName).font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(.white).padding()
                .background(Color(red: 0.15, green: 0.15, blue: 0.15)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(routineName.isEmpty ? Color(red: 0.3, green: 0.3, blue: 0.3) : activeNeonColor, lineWidth: 2))
                .shadow(color: routineName.isEmpty ? Color.clear : activeNeonColor, radius: 5)
        }
    }

    private var installButtonSection: some View {
            VStack {
                Button {
                    // 1. 完了の振動フィードバック
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    
                    // 🏎️ 2. パーツの組み立て処理（DraftPart -> RoutineExercise）
                    // .enumerated() を使って、リストの「順番（index）」も一緒に取得して orderIndex にセットします
                    let convertedExercises = partsList.enumerated().map { (index, draftPart) -> RoutineExercise in
                        return RoutineExercise(
                            name: draftPart.name,
                            target: "その他", // DraftPartには部位情報がないので一旦「その他」で固定
                            equipment: draftPart.equipment,
                            baseWeight: draftPart.weight,
                            baseReps: draftPart.reps,
                            sets: draftPart.sets,
                            orderIndex: index // 👈 ここで順番をバッチリ記憶！
                        )
                    }
                    
                    // 💾 3. SwiftDataへ保存（車体に組み込んでセーブ）
                    if let existing = routineToEdit {
                        // 編集モード：既存のルーティンを上書き
                        existing.title = routineName
                        existing.themeColor = selectedColor
                        
                        // 既存の種目を一旦クリアしてから新しいリストを入れる（重複防止）
                        existing.exercises.removeAll()
                        existing.exercises = convertedExercises
                        
                    } else {
                        // 新規作成モード：新しいルーティンを作成
                        let newRoutine = WorkoutRoutine(title: routineName, themeColor: selectedColor)
                        newRoutine.exercises = convertedExercises
                        context.insert(newRoutine) // データベースに登録
                    }
                    
                    // 4. ガレージを出る（メニュー画面に戻る）
                    dismiss()
                    
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("INSTALL BUILD").font(.system(.title3, design: .rounded).weight(.black)).italic()
                    }
                    .foregroundColor(routineName.isEmpty ? .gray : .white).frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(routineName.isEmpty ? Color.gray.opacity(0.2) : activeNeonColor).clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(ZStack { if !routineName.isEmpty {
                        RoundedRectangle(cornerRadius: 20).stroke(activeNeonColor, lineWidth: 6).blur(radius: 4).scaleEffect(isPulsing ? 1.5 : 1.0).opacity(isPulsing ? 0.0 : 0.6)
                        RoundedRectangle(cornerRadius: 20).stroke(activeNeonColor, lineWidth: 2).scaleEffect(isPulsing ? 1.4 : 1.0).opacity(isPulsing ? 0.0 : 1.0)
                    }})
                    .shadow(color: routineName.isEmpty ? .clear : activeNeonColor, radius: 10)
                }
                .disabled(routineName.isEmpty).padding(.horizontal, 24).padding(.bottom, 30)
            }
        }
    
    private var customNavBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.title3.weight(.bold))
                    Text("MENU").font(.system(.headline, design: .rounded).weight(.bold))
                }
                .foregroundColor(.gray)
            }
            Spacer()
            Text(routineToEdit == nil ? "NEW BUILD" : "EDIT BUILD").font(.system(.headline, design: .rounded).weight(.black)).foregroundColor(.white)
            Spacer()
            Text("MENU").font(.headline).foregroundColor(Color.clear)
        }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
    }
}
