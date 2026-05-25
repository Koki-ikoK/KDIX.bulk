# REDLINE // Workout Management App

**REDLINE** は、ワークアウトの成果を「音」と「映像」で演出し、仲間と高め合うための次世代ワークアウト・ログ・プラットフォームです。

単なる数字の記録に留まらず、レーシングマシンのような高揚感と、コミュニティとの繋がりを提供します。

## Key Features

### 1. Real-time Nitro System
仲間のワークアウト中にリアルタイムで「ニトロ（応援）」を送り合うことができます。通知と音の演出により、トレーニング中の孤独感を払拭し、モチベーションを劇的に向上させます。

### 2. HUD Style Social Sharing
自分のトレーニング成果（総重量、経過時間、人体モデル）を、リッチなHUD（ヘッドアップディスプレイ）デザインで1枚の画像として動的に生成。内蔵カメラでの自撮りや、お気に入りのスタイルを選択して、シームレスにアプリ内フィードやSNSへ投稿できます。

### 3. Community Feed & Routine Import
仲間の「ミッションレポート（共有結果）」をリアルタイムで閲覧可能。他のユーザーが公開している優れたトレーニングメニューが気になったら、ボタン一つで自分のアプリに「IMPORT」して採用することができます。

### 4. High-Performance Architecture
- **SwiftData**: Apple最新のフレームワークを用いた高速なローカルデータ管理。
- **Firebase Sync**: 匿名認証を用いたセキュアなリアルタイム同期。
- **AVFoundation**: エンジン音のSE再生やカスタムカメラ制御による没入感のある体験。

## Tech Stack

| Category | Technology |
| :--- | :--- |
| **Language** | Swift 5.10+ (Concurrency) |
| **Framework** | SwiftUI |
| **Local DB** | SwiftData |
| **Backend** | Firebase (Firestore, Auth) |
| **Media** | AVFoundation, ImageRenderer |
| **Architecture** | MVVM + Feature-based Directory Structure |

## Setup (Important)

本プロジェクトは、セキュリティ保護のためFirebaseの設定ファイル（`GoogleService-Info.plist`）をリポジトリに含めていません。

### ビルド手順:
1. [Firebase Console](https://console.firebase.google.com/) で新規プロジェクトを作成。
2. iOSアプリを追加し、`GoogleService-Info.plist` をダウンロード。
3. ダウンロードしたファイルを、以下のパスに配置してください。
   `KDIX.bulk/KDIX.bulk/Resources/Plists/GoogleService-Info.plist`
4. Xcodeで `KDIX.bulk.xcodeproj` を開き、ビルドターゲットに実機またはシミュレーターを選択して実行してください。

---

*Developed by Koki*
