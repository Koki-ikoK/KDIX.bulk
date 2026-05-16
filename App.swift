//
//  app.swift
//  KDIX.bulk
//
//  Created by Koki Iwaki on 2026/04/05.
//

import SwiftUI
import SwiftData

@main  // 👈 この一行が超重要！これが「玄関口」の印です
struct KDIX_bulkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView() // 👈 最初に表示する画面
        }
        .modelContainer(for: [WorkoutLog.self, WorkoutRoutine.self])
    }
}
