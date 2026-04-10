//
//  HealthKitManager.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import HealthKit

/// HealthKit ile adım verisi senkronizasyonu
@Observable
final class HealthKitManager {
    private let healthStore = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// HealthKit izinlerini iste
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    /// Son N gün için adım verisi
    func fetchLastDays(_ count: Int) async -> [(Date, Int)] {
        guard isAvailable,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return []
        }

        let calendar = Calendar.current
        var results: [(Date, Int)] = []

        for offset in 0..<count {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date

            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

            let steps = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, _ in
                    let value = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
            results.append((date, steps))
        }

        return results
    }
}
