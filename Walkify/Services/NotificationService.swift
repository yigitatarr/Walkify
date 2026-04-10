//
//  NotificationService.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import UserNotifications

@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Smart Notifications

    func scheduleAllNotifications(goal: Int, stepsToday: Int, currentStreak: Int) {
        cancelAll()

        let stepsLeft = goal - stepsToday
        guard stepsLeft > 0 else {
            scheduleGoalCelebration(streak: currentStreak)
            return
        }

        let progressPercent = Double(stepsToday) / Double(goal) * 100

        scheduleMorningMotivation(goal: goal, streak: currentStreak)
        scheduleMiddayProgress(stepsLeft: stepsLeft, streak: currentStreak, progressPercent: progressPercent)
        scheduleAfternoonPush(stepsLeft: stepsLeft, streak: currentStreak, progressPercent: progressPercent)
        scheduleEveningFinalPush(stepsLeft: stepsLeft, streak: currentStreak, progressPercent: progressPercent)

        if currentStreak >= 1 {
            scheduleStreakProtection(stepsLeft: stepsLeft, streak: currentStreak)
        }
    }

    // MARK: - Background Progress Notification

    func sendBackgroundProgressNotification(goal: Int, stepsToday: Int, currentStreak: Int) {
        let stepsLeft = max(0, goal - stepsToday)
        let progressPercent = Double(stepsToday) / Double(goal) * 100

        let content = UNMutableNotificationContent()
        content.sound = nil
        content.categoryIdentifier = "WALKIFY_PROGRESS_BG"

        if stepsLeft <= 0 {
            content.title = "Tebrikler! Günlük hedefine ulaştın! 🎉"
            if currentStreak > 0 {
                content.subtitle = "\(currentStreak + 1) günlük seri!"
            }
            content.body = "Bugün \(formatNumber(stepsToday)) adım attın. Harika iş!"
        } else if currentStreak > 0 {
            content.title = "\(currentStreak) günlük seri için \(formatNumber(stepsLeft)) adım kaldı! 🎯"
            content.subtitle = progressSubtitle(progressPercent: progressPercent)
            content.body = progressBody(stepsToday: stepsToday, stepsLeft: stepsLeft, progressPercent: progressPercent)
        } else {
            content.title = "Hedefe \(formatNumber(stepsLeft)) adım kaldı! 🎯"
            content.subtitle = progressSubtitle(progressPercent: progressPercent)
            content.body = progressBody(stepsToday: stepsToday, stepsLeft: stepsLeft, progressPercent: progressPercent)
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "background_progress", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func clearDeliveredProgressNotification() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["background_progress"])
    }

    private func progressSubtitle(progressPercent: Double) -> String {
        switch progressPercent {
        case 0..<15:
            return "Güne enerjik başla!"
        case 15..<35:
            return "İyi gidiyorsun, devam et!"
        case 35..<55:
            return "Yarı yola geliyorsun!"
        case 55..<75:
            return "Harika gidiyorsun!"
        case 75..<90:
            return "Güçlü kal, bitiş çizgisi yakında!"
        default:
            return "Son hamle, bitir bu işi!"
        }
    }

    private func progressBody(stepsToday: Int, stepsLeft: Int, progressPercent: Double) -> String {
        if progressPercent >= 90 {
            return "Sadece \(formatNumber(stepsLeft)) adım! Kısa bir yürüyüş yeter."
        } else if progressPercent >= 70 {
            return "\(formatNumber(stepsToday)) adım attın. Hedefe çok yakınsın!"
        } else if progressPercent >= 50 {
            return "\(formatNumber(stepsToday)) adım attın. Öğleden sonra biraz yürü ve hedefe ulaş."
        } else if progressPercent >= 25 {
            return "\(formatNumber(stepsToday)) adım attın. Yürüyüşe çıkarak ivme kazan!"
        } else {
            return "Bugün henüz \(formatNumber(stepsToday)) adım attın. Haydi harekete geç!"
        }
    }

    // MARK: - Morning (09:00)

    private func scheduleMorningMotivation(goal: Int, streak: Int) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "WALKIFY_MOTIVATION"

        if streak > 0 {
            content.title = "Günaydın! \(streak) günlük serin devam ediyor 🔥"
            content.body = morningBody(goal: goal, streak: streak)
        } else {
            content.title = "Günaydın! Bugün harika bir gün 🌅"
            content.body = "Hedefin \(formatNumber(goal)) adım. Yeni bir seri başlatmak için harika bir gün!"
        }

        schedule(at: 9, 0, content: content, identifier: "morning_motivation")
    }

    private func morningBody(goal: Int, streak: Int) -> String {
        switch streak {
        case 1...3:
            return "Bugünkü hedefin \(formatNumber(goal)) adım. Seriyi büyütmeye devam et!"
        case 4...7:
            return "\(streak) günlük seri harika! Bugün de \(formatNumber(goal)) adım atarak devam et."
        case 8...14:
            return "Muhteşem bir \(streak) günlük seri! Bu ivmeyi kaybetme."
        case 15...30:
            return "İnanılmaz! \(streak) gündür durdurulamıyorsun. Bugün de hedefe ulaş!"
        default:
            return "Efsanevi \(streak) günlük seri! Bugün de \(formatNumber(goal)) adım atarak tarih yaz."
        }
    }

    // MARK: - Midday (13:00)

    private func scheduleMiddayProgress(stepsLeft: Int, streak: Int, progressPercent: Double) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "WALKIFY_PROGRESS"

        if streak > 0 {
            content.title = "\(streak) günlük seri için \(formatNumber(stepsLeft)) adım kaldı!"
            content.subtitle = middaySubtitle(progressPercent: progressPercent)
        } else {
            content.title = "Hedefe \(formatNumber(stepsLeft)) adım kaldı 🎯"
            content.subtitle = middaySubtitle(progressPercent: progressPercent)
        }

        content.body = middayBody(progressPercent: progressPercent, stepsLeft: stepsLeft)

        schedule(at: 13, 0, content: content, identifier: "midday_progress")
    }

    private func middaySubtitle(progressPercent: Double) -> String {
        switch progressPercent {
        case 0..<10:
            return "Haydi, ilk adımı at!"
        case 10..<30:
            return "İyi bir başlangıç, devam et!"
        case 30..<50:
            return "Yarı yola geliyorsun!"
        case 50..<70:
            return "Harika gidiyorsun!"
        case 70..<90:
            return "Hedefe çok yakınsın!"
        default:
            return "Son hamle, bitir bu işi!"
        }
    }

    private func middayBody(progressPercent: Double, stepsLeft: Int) -> String {
        if progressPercent < 25 {
            return "Öğle yürüyüşü tam zamanı! Kısa bir tur bile fark yaratır."
        } else if progressPercent < 50 {
            return "Öğleden sonra kısa bir yürüyüş hedefe ulaşmana yardımcı olur."
        } else {
            return "Güzel gidiyorsun, \(formatNumber(stepsLeft)) adım daha ve hedeftesin!"
        }
    }

    // MARK: - Afternoon (16:00)

    private func scheduleAfternoonPush(stepsLeft: Int, streak: Int, progressPercent: Double) {
        guard stepsLeft > 500 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "WALKIFY_PUSH"

        if streak > 0 && progressPercent < 70 {
            content.title = "\(streak) günlük seri tehlikede! ⚠️"
            content.subtitle = "Güçlü kal, bitiş çizgisi yakında!"
            content.body = "Hedefe \(formatNumber(stepsLeft)) adım kaldı. Kısa bir yürüyüş seriyi kurtarır!"
        } else if progressPercent >= 70 {
            content.title = "Hedefe çok az kaldı! 🏃"
            content.subtitle = "Son hamle, bitir bu işi!"
            content.body = "Sadece \(formatNumber(stepsLeft)) adım daha. Bunu yapabilirsin!"
        } else {
            content.title = "Yürüyüş zamanı! 🚶"
            content.subtitle = "Akşam olmadan hedefe yaklaş."
            content.body = "Hedefe \(formatNumber(stepsLeft)) adım kaldı. Bir yürüyüş her şeyi değiştirir."
        }

        schedule(at: 16, 0, content: content, identifier: "afternoon_push")
    }

    // MARK: - Evening (20:00)

    private func scheduleEveningFinalPush(stepsLeft: Int, streak: Int, progressPercent: Double) {
        guard stepsLeft > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "WALKIFY_EVENING"

        if stepsLeft <= 1000 {
            if streak > 0 {
                content.title = "\(streak + 1). gün için \(formatNumber(stepsLeft)) adım kaldı! 🎯"
                content.subtitle = "Güçlü kal, bitiş çizgisi yakında!"
                content.body = "Bu kadar yakınken bırakma! Kısa bir yürüyüş yeter."
            } else {
                content.title = "Hedefe \(formatNumber(stepsLeft)) adım kaldı! 🎯"
                content.subtitle = "Son hamle, bitir bu işi!"
                content.body = "Neredeyse hedefe ulaştın, son bir hamle!"
            }
        } else {
            if streak > 0 {
                content.title = "\(streak) günlük serin bugün bitmesin! 🔥"
                content.subtitle = "\(formatNumber(stepsLeft)) adım daha atabilirsin."
                content.body = eveningMotivation(streak: streak)
            } else {
                content.title = "Bugün hedefe ulaşamadın, ama yarın yeni bir gün! 💪"
                content.body = "Her gün yeni bir fırsat. Yarın daha güçlü döneceksin!"
            }
        }

        schedule(at: 20, 0, content: content, identifier: "evening_final")
    }

    private func eveningMotivation(streak: Int) -> String {
        switch streak {
        case 1...5:
            return "Seriyi korumak için son şans! Akşam yürüyüşü tam sana göre."
        case 6...14:
            return "\(streak) günlük emeğin boşa gitmesin. Bir tur at ve seriyi koru!"
        case 15...30:
            return "Bu muhteşem seriyi kaybetme! Sadece bir yürüyüş uzağındasın."
        default:
            return "Efsanevi serini koru! Bu kadar yoldan sonra durma."
        }
    }

    // MARK: - Streak Protection (21:30)

    private func scheduleStreakProtection(stepsLeft: Int, streak: Int) {
        guard stepsLeft > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "WALKIFY_STREAK"

        content.title = "🚨 \(streak) günlük seri için \(formatNumber(stepsLeft)) adım kaldı!"
        content.subtitle = "Güçlü kal, bitiş çizgisi yakında!"

        if stepsLeft <= 500 {
            content.body = "Sadece \(formatNumber(stepsLeft)) adım! 5 dakikalık bir yürüyüş yeter. Haydi!"
        } else if stepsLeft <= 2000 {
            content.body = "15 dakikalık bir yürüyüş seriyi kurtarır. Şimdi ya da asla!"
        } else {
            content.body = "Bugün hedefe ulaşmak zor ama yarın yeni bir başlangıç yapabilirsin."
        }

        schedule(at: 21, 30, content: content, identifier: "streak_protection")
    }

    // MARK: - Goal Celebration

    func scheduleGoalCelebration(streak: Int = 0) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "WALKIFY_CELEBRATION"

        if streak > 0 {
            content.title = "Tebrikler! 🎉 \(streak + 1) günlük seri!"
            content.subtitle = "Hedefe ulaştın, muhteşemsin!"
            content.body = celebrationBody(streak: streak + 1)
        } else {
            content.title = "Tebrikler! 🎉"
            content.subtitle = "Günlük hedefini tamamladın!"
            content.body = "Harika bir iş çıkardın. Yarın da böyle devam et!"
        }

        schedule(at: nil, nil, content: content, identifier: "goal_celebration")
    }

    private func celebrationBody(streak: Int) -> String {
        switch streak {
        case 1...3:
            return "Güzel başlangıç! Seriyi devam ettir."
        case 4...7:
            return "Bir haftalık seri yakın! Devam et!"
        case 8...14:
            return "İki haftalık seri hedefine yaklaşıyorsun. Muhteşem!"
        case 15...30:
            return "Bir aylık seri hayal değil! İnanılmaz gidiyorsun."
        case 31...60:
            return "Bir ayı geçtin! Artık bu bir yaşam tarzı."
        default:
            return "\(streak) gün! Efsane olma yolundasın."
        }
    }

    // MARK: - Scheduling

    private func schedule(at hour: Int?, _ minute: Int?, content: UNMutableNotificationContent, identifier: String) {
        let trigger: UNNotificationTrigger
        if let hour = hour, let minute = minute {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Test Notifications

    func sendSampleNotifications() {
        requestAuthorization { granted in
            guard granted else { return }
            let samples: [(TimeInterval, String, String, String)] = [
                (3, "18 günlük seri için 900 adım kaldı! 🎯", "Güçlü kal, bitiş çizgisi yakında!", "Son bir yürüyüş yeter. Haydi!"),
                (6, "Hedefe çok az kaldı! 🏃", "Son hamle, bitir bu işi!", "Sadece 2.000 adım daha. Bunu yapabilirsin!"),
                (9, "🚨 5 günlük seri tehlikede!", "3.500 adım daha atabilirsin.", "Seriyi korumak için son şans!"),
                (12, "Tebrikler! 🎉 19 günlük seri!", "Hedefe ulaştın, muhteşemsin!", "İki haftalık seri hedefine yaklaşıyorsun. Muhteşem!")
            ]
            for (i, (delay, title, subtitle, body)) in samples.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = title
                content.subtitle = subtitle
                content.body = body
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                let request = UNNotificationRequest(identifier: "sample_\(i)_\(UUID().uuidString)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func formatNumber(_ n: Int) -> String {
        NumberFormatter.stepsFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
