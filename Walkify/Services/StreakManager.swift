//
//  StreakManager.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import SwiftData

/// Üst üste hedef tamamlama serisi hesaplar
struct StreakManager {

    /// Kaç gün üst üste hedefe ulaşılmış
    static func currentStreak(stepRecords: [StepRecord], goal: Int) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let steps = stepRecords
                .filter { calendar.isDate($0.date, inSameDayAs: checkDate) }
                .reduce(0) { $0 + $1.steps }

            if steps >= goal {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previous
            } else {
                break
            }
        }

        return streak
    }

    /// Tüm zamanların en uzun streak'i
    static func longestStreak(stepRecords: [StepRecord], goal: Int) -> Int {
        let calendar = Calendar.current
        guard let oldestDate = stepRecords.map(\.date).min() else { return 0 }
        var longest = 0
        var current = 0
        var checkDate = calendar.startOfDay(for: oldestDate)
        let endDate = calendar.startOfDay(for: Date())

        while checkDate <= endDate {
            let steps = stepRecords
                .filter { calendar.isDate($0.date, inSameDayAs: checkDate) }
                .reduce(0) { $0 + $1.steps }
            if steps >= goal {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = next
        }
        return longest
    }

    /// Bu hafta hedefe kaç gün ulaşıldı
    static func daysReachedGoalThisWeek(stepRecords: [StepRecord], goal: Int) -> (reached: Int, total: Int) {
        let calendar = Calendar.current
        var reached = 0
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let steps = stepRecords
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.steps }
            if steps >= goal { reached += 1 }
        }
        return (reached, 7)
    }

}
