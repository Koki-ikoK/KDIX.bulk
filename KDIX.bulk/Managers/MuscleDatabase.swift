import SwiftUI

// MARK: - 🧬 科学的トレーニングデータ・ベース
struct BiomechanicalData {
    let part: VectorMusclePart
    let recoveryHours: Int
    let fiberType: String
    let optimalReps: String
    let advice: String
}

class MuscleDatabase {
    static let shared = MuscleDatabase()
    
    // 部位ごとの詳細データ (JSONから抽出)
    let muscleInfo: [VectorMusclePart: BiomechanicalData] = [
        .deltoid: BiomechanicalData(part: .deltoid, recoveryHours: 48, fiberType: "混合型 (Type I: 35-74%)", optimalReps: "6-20回", advice: "多方向への負荷蓄積が大きいため、十分な休息を挟みながら多角的に刺激してください。"),
        .biceps: BiomechanicalData(part: .biceps, recoveryHours: 48, fiberType: "やや速筋優位 (Type II: 55-60%)", optimalReps: "8-12回", advice: "毛細血管が豊富で回復は早めですが、丁寧な収縮を意識したトレーニングが効果的です。"),
        .triceps: BiomechanicalData(part: .triceps, recoveryHours: 48, fiberType: "著しい速筋優位 (Type II: 67%)", optimalReps: "6-10回", advice: "速筋比率が高く損傷しやすいため、無理な高重量より確実なフォームを。"),
        .forearm: BiomechanicalData(part: .forearm, recoveryHours: 24, fiberType: "遅筋優位", optimalReps: "10-30回", advice: "血流は豊富ですが、等尺性疲労が溜まりやすいためオーバーワークに注意。"),
        .upperChest: BiomechanicalData(part: .upperChest, recoveryHours: 72, fiberType: "速筋優位 (Type II: 60%)", optimalReps: "6-10回", advice: "鎖骨部を標的とした機械的過負荷が効果的です。"),
        .midChest: BiomechanicalData(part: .midChest, recoveryHours: 72, fiberType: "速筋優位 (Type II: 60%)", optimalReps: "8-12回", advice: "水平内転による力学的テンションを重視してください。"),
        .lowerChest: BiomechanicalData(part: .lowerChest, recoveryHours: 72, fiberType: "速筋優位 (Type II: 60%)", optimalReps: "6-10回", advice: "腹頭部線維の最大収縮を誘導してください。"),
        .obliques: BiomechanicalData(part: .obliques, recoveryHours: 24, fiberType: "やや遅筋優位", optimalReps: "10-25回", advice: "高疲労耐性筋群です。収縮と伸張を丁寧に繰り返してください。"),
        .abs: BiomechanicalData(part: .abs, recoveryHours: 24, fiberType: "やや遅筋優位", optimalReps: "10-30回", advice: "修復速度が早く、高頻度な刺激にも耐えうる部位です。"),
        .quads: BiomechanicalData(part: .quads, recoveryHours: 72, fiberType: "速筋優位 (57-65%)", optimalReps: "6-10回", advice: "全身で最も体積が大きく、神経疲労も強いため、強度の高いセッションを心がけて。"),
        .calves: BiomechanicalData(part: .calves, recoveryHours: 24, fiberType: "混合型/著しく遅筋優位", optimalReps: "8-25回", advice: "ターンオーバーが非常に早く、日常的な刺激に強い部位です。"),
        .back: BiomechanicalData(part: .back, recoveryHours: 72, fiberType: "混合型/遅筋優位/速筋優位の複合", optimalReps: "8-15回", advice: "巨大な複合体であり、全身の神経疲労を招きやすいため、計画的なメニュー構成を。")
    ]
    
    // 種目名から詳細部位へのマッピング (JSONから抽出)
    func getVectorPart(for exerciseName: String) -> VectorMusclePart {
        let mapping: [String: VectorMusclePart] = [
            // 胸
            "バーベル・ベンチプレス": .midChest,
            "ダンベル・ベンチプレス": .midChest,
            "インクライン・バーベルプレス": .upperChest,
            "インクライン・ダンベルプレス": .upperChest,
            "デクライン・バーベルプレス": .lowerChest,
            "デクライン・ダンベルプレス": .lowerChest,
            "ダンベルフライ": .midChest,
            "インクライン・ダンベルフライ": .upperChest,
            "デクライン・ダンベルフライ": .lowerChest,
            "ケーブルクロスオーバー (ハイ)": .lowerChest,
            "ケーブルクロスオーバー (ミッド)": .midChest,
            "ケーブルクロスオーバー (ロー)": .upperChest,
            "ペックデックフライ": .midChest,
            "チェストプレス": .midChest,
            "インクライン・チェストプレス": .upperChest,
            "スミス・ベンチプレス": .midChest,
            "スミス・インクラインプレス": .upperChest,
            "ディップス (胸狙い)": .lowerChest,
            "プッシュアップ (腕立て伏せ)": .midChest,
            "加重ディップス": .lowerChest,
            "加重プッシュアップ": .midChest,
            
            // 背中
            "デッドリフト (コンベンショナル)": .back,
            "デッドリフト (スモウ)": .back,
            "ハーフ・デッドリフト": .back,
            "チンニング (順手)": .back,
            "チンニング (逆手)": .back,
            "チンニング (パラレル)": .back,
            "加重チンニング": .back,
            "ラットプルダウン (フロント)": .back,
            "ラットプルダウン (ビハインドネック)": .back,
            "リバースグリップ・ラットプル": .back,
            "Vバー・ラットプルダウン": .back,
            "ハイロウ (上から引く)": .back,
            "ローロウ (前から引く)": .back,
            "ベントオーバーロウ (順手)": .back,
            "ベントオーバーロウ (逆手)": .back,
            "ペンドレイロウ": .back,
            "ワンハンド・ダンベルロウ": .back,
            "インクライン・ダンベルロウ": .back,
            "シーテッドロウ": .back,
            "ワンハンド・ケーブルロウ": .back,
            "Tバーロウ": .back,
            "マシンロウ": .back,
            "ストレートアーム・プルダウン": .back,
            "ダンベル・プルオーバー": .back,
            "ケーブル・プルオーバー": .back,
            "バーベル・シュラッグ": .back,
            "ダンベル・シュラッグ": .back,
            
            // 脚
            "バーベル・スクワット (ハイバー)": .quads,
            "バーベル・スクワット (ローバー)": .back, // ポステリアチェーン
            "フロント・スクワット": .quads,
            "ゴブレット・スクワット": .quads,
            "スミス・スクワット": .quads,
            "レッグプレス (45度)": .quads,
            "レッグプレス (ホリゾンタル)": .quads,
            "ハックスクワット": .quads,
            "Vスクワット": .quads,
            "ブルガリアンスクワット": .quads,
            "スプリット・スクワット": .quads,
            "ウォーキング・ランジ": .quads,
            "レッグエクステンション": .quads,
            "レッグカール (プローン)": .quads, // ハムだがquadsにまとめるか拡張待ち
            "レッグカール (シーテッド)": .quads,
            "ルーマニアン・デッドリフト (RDL)": .back,
            "ダンベル・RDL": .back,
            "スティフレッグド・デッドリフト": .back,
            "グッドモーニング": .back,
            "ヒップスラスト": .back,
            "カーフレイズ (スタンディング)": .calves,
            "カーフレイズ (シーテッド)": .calves,
            "レッグプレス・カーフレイズ": .calves,
            
            // 肩
            "オーバーヘッドプレス (OHP)": .deltoid,
            "ダンベル・ショルダープレス": .deltoid,
            "アーノルドプレス": .deltoid,
            "スミス・ショルダープレス": .deltoid,
            "マシン・ショルダープレス": .deltoid,
            "サイドレイズ": .deltoid,
            "インクライン・サイドレイズ": .deltoid,
            "ケーブル・サイドレイズ": .deltoid,
            "マシン・サイドレイズ": .deltoid,
            "フロントレイズ (ダンベル)": .deltoid,
            "フロントレイズ (バーベル)": .deltoid,
            "フロントレイズ (ケーブル)": .deltoid,
            "リアレイズ (ダンベル)": .deltoid,
            "リアレイズ (インクライン)": .deltoid,
            "リアデルデルトフライ (マシン)": .deltoid,
            "フェイスプル": .deltoid,
            "アップライトロウ (バーベル)": .deltoid,
            "アップライトロウ (ケーブル)": .deltoid,
            
            // 腕
            "バーベルカール": .biceps,
            "EZバー・カール": .biceps,
            "ダンベルカール": .biceps,
            "ハンマーカール": .biceps,
            "インクライン・ダンベルカール": .biceps,
            "コンセントレーションカール": .biceps,
            "プリーチャーカール": .biceps,
            "スパイダーカール": .biceps,
            "ケーブルカール": .biceps,
            "リバースカール": .forearm,
            "ナローグリップ・ベンチプレス": .triceps,
            "スカルクラッシャー": .triceps,
            "フレンチプレス": .triceps,
            "ケーブル・プッシュダウン (ストレートバー)": .triceps,
            "ケーブル・プッシュダウン (ロープ)": .triceps,
            "オーバーヘッド・トライセプスエクステンション": .triceps,
            "キックバック": .triceps,
            "ディップス (三頭狙い)": .triceps,
            "トライセプス・マシン": .triceps,
            "リストカール": .forearm,
            "リバース・リストカール": .forearm,
            
            // 腹
            "クランチ": .abs,
            "シットアップ": .abs,
            "レッグレイズ": .abs,
            "ハンギング・レッグレイズ": .abs,
            "ハンギング・ニーレイズ": .abs,
            "アブローラー (立ちコロ)": .abs,
            "アブローラー (膝コロ)": .abs,
            "ケーブルクランチ": .abs,
            "アブドミナル・マシン": .abs,
            "ロシアンツイスト": .obliques,
            "ウッドチョッパー": .obliques,
            "プランク": .abs,
            "サイドプランク": .obliques,
            "ドラゴンフラッグ": .abs
        ]
        return mapping[exerciseName] ?? .abs // デフォルト
    }
}
