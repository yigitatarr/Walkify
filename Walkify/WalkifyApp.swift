//
//  WalkifyApp.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

@main
struct WalkifyApp: App {
    init() {
        _ = NotificationService.shared
    }
    @Environment(\.scenePhase) private var scenePhase
    @State private var stepDataManager = StepDataManager()
    @State private var watchManager = WatchConnectionManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StepRecord.self,
            UserProfile.self,
            EarnedBadge.self,
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            #if DEBUG
            print("ModelContainer failed, clearing old store: \(error)")
            #endif
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let fm = FileManager.default
                if let files = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
                    for file in files where file.lastPathComponent.hasSuffix(".store") || file.lastPathComponent.hasSuffix(".store-wal") || file.lastPathComponent.hasSuffix(".store-shm") {
                        try? fm.removeItem(at: file)
                    }
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [memConfig])
                } catch {
                    fatalError("ModelContainer oluşturulamadı: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stepDataManager)
                .environment(watchManager)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                stepDataManager.configure(modelContext: sharedModelContainer.mainContext)
                let isPaused = (try? sharedModelContainer.mainContext.fetch(FetchDescriptor<UserProfile>()))?.first?.isStepTrackingPaused ?? false
                if !isPaused {
                    stepDataManager.startLiveUpdates()
                    Task {
                        await stepDataManager.syncHistoricalData()
                    }
                } else {
                    stepDataManager.stopLiveUpdates()
                }
                NotificationService.shared.clearDeliveredProgressNotification()
                NotificationService.shared.requestAuthorization { _ in }
                scheduleNotificationsIfNeeded()
            case .background:
                stepDataManager.stopLiveUpdates()
                sendBackgroundNotification()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    private func sendBackgroundNotification() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        let recordsDescriptor = FetchDescriptor<StepRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let profile = (try? context.fetch(descriptor))?.first,
              profile.notificationsEnabled,
              let records = try? context.fetch(recordsDescriptor) else { return }

        let goal = profile.dailyStepGoal
        let stepsToday = records
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.steps }
        let streak = StreakManager.currentStreak(stepRecords: records, goal: goal)

        NotificationService.shared.sendBackgroundProgressNotification(
            goal: goal,
            stepsToday: stepsToday,
            currentStreak: streak
        )
    }

    private func scheduleNotificationsIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        let recordsDescriptor = FetchDescriptor<StepRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let profile = (try? context.fetch(descriptor))?.first,
              profile.notificationsEnabled,
              let records = try? context.fetch(recordsDescriptor) else {
            NotificationService.shared.cancelAll()
            return
        }

        let goal = profile.dailyStepGoal
        let stepsToday = records
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.steps }

        let streak = StreakManager.currentStreak(stepRecords: records, goal: goal)

        NotificationService.shared.scheduleAllNotifications(
            goal: goal,
            stepsToday: stepsToday,
            currentStreak: streak
        )
    }
}
