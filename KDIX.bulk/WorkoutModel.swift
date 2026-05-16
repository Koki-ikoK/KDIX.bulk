import Foundation
import SwiftUI
import SwiftData

// 👇 これを追加！ユーザーが独自に作成した種目を保存するためのデータベース
@Model class CustomExercise {
    var id: UUID = UUID()
    var name: String
    var target: String
    var equipment: String
    var defaultWeight: Double
    var defaultReps: Int
    
    init(name: String, target: String = "その他", equipment: String = "その他", defaultWeight: Double = 20.0, defaultReps: Int = 10) {
        self.name = name
        self.target = target
        self.equipment = equipment
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
    }
}

@Model
class SetRecordEntity {
    var setNumber: Int
    var weight: Double
    var reps: Int
    init(setNumber: Int, weight: Double, reps: Int) {
        self.setNumber = setNumber; self.weight = weight; self.reps = reps
    }
}

@Model
class ExerciseLog {
    var name: String
    var memo: String = ""
    @Relationship(deleteRule: .cascade) var sets: [SetRecordEntity] = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
class WorkoutLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var dayTitle: String = ""
    var themeColor: String = "blue"
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseLog] = []
    var totalSeconds: Int = 0
    
    init(dayTitle: String, totalSeconds: Int, themeColor: String = "blue") {
        self.dayTitle = dayTitle
        self.totalSeconds = totalSeconds
        self.themeColor = themeColor
        self.date = Date()
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + (Double($1.reps) * $1.weight) }
        }
    }
}

@Model class WorkoutRoutine {
    var id: UUID = UUID()
    var title: String
    var themeColor: String
    @Relationship(deleteRule: .cascade) var exercises: [RoutineExercise] = []
    init(title: String, themeColor: String) { self.title = title; self.themeColor = themeColor }
}

@Model class RoutineExercise {
    var id: UUID = UUID()
    var name: String; var target: String; var equipment: String
    var baseWeight: Double; var baseReps: Int; var sets: Int
    // 👇 🌟エラーの原因だった「順番を記憶する枠」を追加！
    var orderIndex: Int = 0
    
    init(name: String, target: String, equipment: String, baseWeight: Double, baseReps: Int, sets: Int, orderIndex: Int = 0) {
        self.name = name; self.target = target; self.equipment = equipment; self.baseWeight = baseWeight; self.baseReps = baseReps; self.sets = sets; self.orderIndex = orderIndex
    }
}

enum MuscleGroup: String, CaseIterable, Identifiable { case chest = "胸", back = "背中", legs = "脚", shoulders = "肩", arms = "腕", core = "腹・体幹"; var id: String { self.rawValue } }
enum Equipment: String, CaseIterable, Identifiable { case barbell = "バーベル", dumbbell = "ダンベル", machine = "マシン", cable = "ケーブル", bodyweight = "自重", other = "その他"; var id: String { self.rawValue } }
struct ExerciseMaster: Identifiable { let id = UUID(); let name: String; let target: MuscleGroup; let equipment: Equipment; let defaultWeight: Double; let defaultReps: Int }

// 👇 🌟150種目以上のフルリストに「ハイロウ」「ローロウ」を追加した完全版
let allMasterExercises: [ExerciseMaster] = [
    // MARK: - 胸 (Chest)
    ExerciseMaster(name: "バーベル・ベンチプレス", target: .chest, equipment: .barbell, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "ダンベル・ベンチプレス", target: .chest, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 10),
    ExerciseMaster(name: "インクライン・バーベルプレス", target: .chest, equipment: .barbell, defaultWeight: 50.0, defaultReps: 10),
    ExerciseMaster(name: "インクライン・ダンベルプレス", target: .chest, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 10),
    ExerciseMaster(name: "デクライン・バーベルプレス", target: .chest, equipment: .barbell, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "デクライン・ダンベルプレス", target: .chest, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 10),
    ExerciseMaster(name: "ダンベルフライ", target: .chest, equipment: .dumbbell, defaultWeight: 12.0, defaultReps: 12),
    ExerciseMaster(name: "インクライン・ダンベルフライ", target: .chest, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 12),
    ExerciseMaster(name: "デクライン・ダンベルフライ", target: .chest, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 12),
    ExerciseMaster(name: "ケーブルクロスオーバー (ハイ)", target: .chest, equipment: .cable, defaultWeight: 15.0, defaultReps: 15),
    ExerciseMaster(name: "ケーブルクロスオーバー (ミッド)", target: .chest, equipment: .cable, defaultWeight: 15.0, defaultReps: 15),
    ExerciseMaster(name: "ケーブルクロスオーバー (ロー)", target: .chest, equipment: .cable, defaultWeight: 10.0, defaultReps: 15),
    ExerciseMaster(name: "ペックデックフライ", target: .chest, equipment: .machine, defaultWeight: 40.0, defaultReps: 12),
    ExerciseMaster(name: "チェストプレス", target: .chest, equipment: .machine, defaultWeight: 50.0, defaultReps: 10),
    ExerciseMaster(name: "インクライン・チェストプレス", target: .chest, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "スミス・ベンチプレス", target: .chest, equipment: .machine, defaultWeight: 50.0, defaultReps: 10),
    ExerciseMaster(name: "スミス・インクラインプレス", target: .chest, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "ディップス (胸狙い)", target: .chest, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "プッシュアップ (腕立て伏せ)", target: .chest, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 15),
    ExerciseMaster(name: "加重ディップス", target: .chest, equipment: .other, defaultWeight: 10.0, defaultReps: 10),
    ExerciseMaster(name: "加重プッシュアップ", target: .chest, equipment: .other, defaultWeight: 10.0, defaultReps: 10),

    // MARK: - 背中 (Back)
    ExerciseMaster(name: "デッドリフト (コンベンショナル)", target: .back, equipment: .barbell, defaultWeight: 100.0, defaultReps: 5),
    ExerciseMaster(name: "デッドリフト (スモウ)", target: .back, equipment: .barbell, defaultWeight: 100.0, defaultReps: 5),
    ExerciseMaster(name: "ハーフ・デッドリフト", target: .back, equipment: .barbell, defaultWeight: 120.0, defaultReps: 5),
    ExerciseMaster(name: "チンニング (順手)", target: .back, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "チンニング (逆手)", target: .back, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "チンニング (パラレル)", target: .back, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "加重チンニング", target: .back, equipment: .other, defaultWeight: 10.0, defaultReps: 8),
    ExerciseMaster(name: "ラットプルダウン (フロント)", target: .back, equipment: .machine, defaultWeight: 45.0, defaultReps: 10),
    ExerciseMaster(name: "ラットプルダウン (ビハインドネック)", target: .back, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "リバースグリップ・ラットプル", target: .back, equipment: .machine, defaultWeight: 45.0, defaultReps: 10),
    ExerciseMaster(name: "Vバー・ラットプルダウン", target: .back, equipment: .machine, defaultWeight: 50.0, defaultReps: 10),
    // 👇 追加リクエスト種目！
    ExerciseMaster(name: "ハイロウ (上から引く)", target: .back, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "ローロウ (前から引く)", target: .back, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "ベントオーバーロウ (順手)", target: .back, equipment: .barbell, defaultWeight: 50.0, defaultReps: 10),
    ExerciseMaster(name: "ベントオーバーロウ (逆手)", target: .back, equipment: .barbell, defaultWeight: 50.0, defaultReps: 10),
    ExerciseMaster(name: "ペンドレイロウ", target: .back, equipment: .barbell, defaultWeight: 60.0, defaultReps: 8),
    ExerciseMaster(name: "ワンハンド・ダンベルロウ", target: .back, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 10),
    ExerciseMaster(name: "インクライン・ダンベルロウ", target: .back, equipment: .dumbbell, defaultWeight: 16.0, defaultReps: 12),
    ExerciseMaster(name: "シーテッドロウ", target: .back, equipment: .cable, defaultWeight: 40.0, defaultReps: 12),
    ExerciseMaster(name: "ワンハンド・ケーブルロウ", target: .back, equipment: .cable, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "Tバーロウ", target: .back, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "マシンロウ", target: .back, equipment: .machine, defaultWeight: 45.0, defaultReps: 10),
    ExerciseMaster(name: "ストレートアーム・プルダウン", target: .back, equipment: .cable, defaultWeight: 20.0, defaultReps: 15),
    ExerciseMaster(name: "ダンベル・プルオーバー", target: .back, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "ケーブル・プルオーバー", target: .back, equipment: .cable, defaultWeight: 20.0, defaultReps: 15),
    ExerciseMaster(name: "バーベル・シュラッグ", target: .back, equipment: .barbell, defaultWeight: 80.0, defaultReps: 12),
    ExerciseMaster(name: "ダンベル・シュラッグ", target: .back, equipment: .dumbbell, defaultWeight: 30.0, defaultReps: 15),

    // MARK: - 脚 (Legs)
    ExerciseMaster(name: "バーベル・スクワット (ハイバー)", target: .legs, equipment: .barbell, defaultWeight: 80.0, defaultReps: 10),
    ExerciseMaster(name: "バーベル・スクワット (ローバー)", target: .legs, equipment: .barbell, defaultWeight: 80.0, defaultReps: 10),
    ExerciseMaster(name: "フロント・スクワット", target: .legs, equipment: .barbell, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "ゴブレット・スクワット", target: .legs, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "スミス・スクワット", target: .legs, equipment: .machine, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "レッグプレス (45度)", target: .legs, equipment: .machine, defaultWeight: 150.0, defaultReps: 12),
    ExerciseMaster(name: "レッグプレス (ホリゾンタル)", target: .legs, equipment: .machine, defaultWeight: 100.0, defaultReps: 12),
    ExerciseMaster(name: "ハックスクワット", target: .legs, equipment: .machine, defaultWeight: 100.0, defaultReps: 10),
    ExerciseMaster(name: "Vスクワット", target: .legs, equipment: .machine, defaultWeight: 80.0, defaultReps: 10),
    ExerciseMaster(name: "ブルガリアンスクワット", target: .legs, equipment: .dumbbell, defaultWeight: 15.0, defaultReps: 10),
    ExerciseMaster(name: "スプリット・スクワット", target: .legs, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 10),
    ExerciseMaster(name: "ウォーキング・ランジ", target: .legs, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 20),
    ExerciseMaster(name: "レッグエクステンション", target: .legs, equipment: .machine, defaultWeight: 40.0, defaultReps: 15),
    ExerciseMaster(name: "レッグカール (プローン/うつ伏せ)", target: .legs, equipment: .machine, defaultWeight: 40.0, defaultReps: 12),
    ExerciseMaster(name: "レッグカール (シーテッド)", target: .legs, equipment: .machine, defaultWeight: 40.0, defaultReps: 12),
    ExerciseMaster(name: "ルーマニアン・デッドリフト (RDL)", target: .legs, equipment: .barbell, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "ダンベル・RDL", target: .legs, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "スティフレッグド・デッドリフト", target: .legs, equipment: .barbell, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "グッドモーニング", target: .legs, equipment: .barbell, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "ヒップスラスト", target: .legs, equipment: .barbell, defaultWeight: 60.0, defaultReps: 10),
    ExerciseMaster(name: "ヒップアブダクション", target: .legs, equipment: .machine, defaultWeight: 40.0, defaultReps: 15),
    ExerciseMaster(name: "ヒップアダクション", target: .legs, equipment: .machine, defaultWeight: 40.0, defaultReps: 15),
    ExerciseMaster(name: "カーフレイズ (スタンディング)", target: .legs, equipment: .machine, defaultWeight: 60.0, defaultReps: 15),
    ExerciseMaster(name: "カーフレイズ (シーテッド)", target: .legs, equipment: .machine, defaultWeight: 40.0, defaultReps: 15),
    ExerciseMaster(name: "レッグプレス・カーフレイズ", target: .legs, equipment: .machine, defaultWeight: 100.0, defaultReps: 15),

    // MARK: - 肩 (Shoulders)
    ExerciseMaster(name: "オーバーヘッドプレス (OHP)", target: .shoulders, equipment: .barbell, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "ダンベル・ショルダープレス", target: .shoulders, equipment: .dumbbell, defaultWeight: 15.0, defaultReps: 10),
    ExerciseMaster(name: "アーノルドプレス", target: .shoulders, equipment: .dumbbell, defaultWeight: 12.0, defaultReps: 10),
    ExerciseMaster(name: "スミス・ショルダープレス", target: .shoulders, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "マシン・ショルダープレス", target: .shoulders, equipment: .machine, defaultWeight: 40.0, defaultReps: 10),
    ExerciseMaster(name: "サイドレイズ", target: .shoulders, equipment: .dumbbell, defaultWeight: 7.0, defaultReps: 15),
    ExerciseMaster(name: "インクライン・サイドレイズ", target: .shoulders, equipment: .dumbbell, defaultWeight: 5.0, defaultReps: 15),
    ExerciseMaster(name: "ケーブル・サイドレイズ", target: .shoulders, equipment: .cable, defaultWeight: 5.0, defaultReps: 15),
    ExerciseMaster(name: "マシン・サイドレイズ", target: .shoulders, equipment: .machine, defaultWeight: 20.0, defaultReps: 15),
    ExerciseMaster(name: "フロントレイズ (ダンベル)", target: .shoulders, equipment: .dumbbell, defaultWeight: 7.0, defaultReps: 15),
    ExerciseMaster(name: "フロントレイズ (バーベル)", target: .shoulders, equipment: .barbell, defaultWeight: 15.0, defaultReps: 12),
    ExerciseMaster(name: "フロントレイズ (ケーブル)", target: .shoulders, equipment: .cable, defaultWeight: 10.0, defaultReps: 15),
    ExerciseMaster(name: "リアレイズ (ダンベル)", target: .shoulders, equipment: .dumbbell, defaultWeight: 5.0, defaultReps: 15),
    ExerciseMaster(name: "インクライン・リアレイズ", target: .shoulders, equipment: .dumbbell, defaultWeight: 5.0, defaultReps: 15),
    ExerciseMaster(name: "リアデルトフライ (マシン)", target: .shoulders, equipment: .machine, defaultWeight: 30.0, defaultReps: 15),
    ExerciseMaster(name: "フェイスプル", target: .shoulders, equipment: .cable, defaultWeight: 20.0, defaultReps: 15),
    ExerciseMaster(name: "アップライトロウ (バーベル)", target: .shoulders, equipment: .barbell, defaultWeight: 30.0, defaultReps: 12),
    ExerciseMaster(name: "アップライトロウ (ケーブル)", target: .shoulders, equipment: .cable, defaultWeight: 20.0, defaultReps: 15),

    // MARK: - 腕 (Arms)
    ExerciseMaster(name: "バーベルカール", target: .arms, equipment: .barbell, defaultWeight: 30.0, defaultReps: 10),
    ExerciseMaster(name: "EZバー・カール", target: .arms, equipment: .barbell, defaultWeight: 25.0, defaultReps: 10),
    ExerciseMaster(name: "ダンベルカール", target: .arms, equipment: .dumbbell, defaultWeight: 12.0, defaultReps: 10),
    ExerciseMaster(name: "ハンマーカール", target: .arms, equipment: .dumbbell, defaultWeight: 12.0, defaultReps: 10),
    ExerciseMaster(name: "インクライン・ダンベルカール", target: .arms, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 10),
    ExerciseMaster(name: "コンセントレーションカール", target: .arms, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 12),
    ExerciseMaster(name: "プリーチャーカール", target: .arms, equipment: .machine, defaultWeight: 20.0, defaultReps: 10),
    ExerciseMaster(name: "スパイダーカール", target: .arms, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 12),
    ExerciseMaster(name: "ケーブルカール", target: .arms, equipment: .cable, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "リバースカール", target: .arms, equipment: .barbell, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "ナローグリップ・ベンチプレス", target: .arms, equipment: .barbell, defaultWeight: 50.0, defaultReps: 10),
    ExerciseMaster(name: "スカルクラッシャー", target: .arms, equipment: .barbell, defaultWeight: 25.0, defaultReps: 10),
    ExerciseMaster(name: "フレンチプレス", target: .arms, equipment: .dumbbell, defaultWeight: 20.0, defaultReps: 10),
    ExerciseMaster(name: "ケーブル・プッシュダウン (ストレートバー)", target: .arms, equipment: .cable, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "ケーブル・プッシュダウン (ロープ)", target: .arms, equipment: .cable, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "オーバーヘッド・トライセプスエクステンション", target: .arms, equipment: .cable, defaultWeight: 20.0, defaultReps: 12),
    ExerciseMaster(name: "キックバック", target: .arms, equipment: .dumbbell, defaultWeight: 7.0, defaultReps: 15),
    ExerciseMaster(name: "ディップス (三頭狙い)", target: .arms, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "トライセプス・マシン", target: .arms, equipment: .machine, defaultWeight: 30.0, defaultReps: 12),
    ExerciseMaster(name: "リストカール", target: .arms, equipment: .barbell, defaultWeight: 20.0, defaultReps: 15),
    ExerciseMaster(name: "リバース・リストカール", target: .arms, equipment: .barbell, defaultWeight: 15.0, defaultReps: 15),

    // MARK: - 腹・体幹 (Core)
    ExerciseMaster(name: "クランチ", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 20),
    ExerciseMaster(name: "シットアップ", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 20),
    ExerciseMaster(name: "レッグレイズ", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 15),
    ExerciseMaster(name: "ハンギング・レッグレイズ", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "ハンギング・ニーレイズ", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 15),
    ExerciseMaster(name: "アブローラー (立ちコロ)", target: .core, equipment: .other, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "アブローラー (膝コロ)", target: .core, equipment: .other, defaultWeight: 0.0, defaultReps: 10),
    ExerciseMaster(name: "ケーブルクランチ", target: .core, equipment: .cable, defaultWeight: 30.0, defaultReps: 15),
    ExerciseMaster(name: "アブドミナル・マシン", target: .core, equipment: .machine, defaultWeight: 40.0, defaultReps: 15),
    ExerciseMaster(name: "ロシアンツイスト", target: .core, equipment: .dumbbell, defaultWeight: 10.0, defaultReps: 20),
    ExerciseMaster(name: "ウッドチョッパー", target: .core, equipment: .cable, defaultWeight: 15.0, defaultReps: 15),
    ExerciseMaster(name: "プランク", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 60),
    ExerciseMaster(name: "サイドプランク", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 60),
    ExerciseMaster(name: "ドラゴンフラッグ", target: .core, equipment: .bodyweight, defaultWeight: 0.0, defaultReps: 10)
]
