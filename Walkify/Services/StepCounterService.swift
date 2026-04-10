//
//  StepCounterService.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import CoreMotion

/// Core Motion ile adım sayımı yapan servis
@Observable
final class StepCounterService {
    private let pedometer = CMPedometer()
    private let calendar = Calendar.current

    var isAuthorized: Bool { CMPedometer.authorizationStatus() == .authorized }
    var isAvailable: Bool { CMPedometer.isStepCountingAvailable() }
    var isFloorCountingAvailable: Bool { CMPedometer.isFloorCountingAvailable() }

    /// Bugünkü adımları al ve callback ile döndür (real-time güncelleme için)
    func startTodayStepCounting(onUpdate: @escaping (Int, Double, Int, Int, Int) -> Void) {
        guard isAvailable else {
            onUpdate(0, 0, 0, 0, 0)
            return
        }

        let startOfDay = calendar.startOfDay(for: Date())

        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            guard self != nil, error == nil, let data = data else {
                return
            }
            let steps = data.numberOfSteps.intValue
            let distance = (data.distance?.doubleValue ?? 0) / 1000
            let calories = ActivityCalculator.caloriesFromSteps(steps, profile: nil)
            let floorsUp = data.floorsAscended?.intValue ?? 0
            let floorsDown = data.floorsDescended?.intValue ?? 0
            DispatchQueue.main.async {
                onUpdate(steps, distance, calories, floorsUp, floorsDown)
            }
        }
    }

    /// Güncel pedometer güncellemelerini durdur
    func stopUpdates() {
        pedometer.stopUpdates()
    }

    /// Belirli bir tarih aralığı için adım verisi al
    func querySteps(from start: Date, to end: Date) async -> (steps: Int, distance: Double, floorsAscended: Int, floorsDescended: Int)? {
        guard isAvailable else { return nil }

        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                guard error == nil, let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                let steps = data.numberOfSteps.intValue
                let distance = (data.distance?.doubleValue ?? 0) / 1000
                let floorsUp = data.floorsAscended?.intValue ?? 0
                let floorsDown = data.floorsDescended?.intValue ?? 0
                continuation.resume(returning: (steps, distance, floorsUp, floorsDown))
            }
        }
    }

    /// Bugün için saatlik adım sayıları (24 eleman: 00:00-01:00, ..., 23:00-24:00)
    func queryHourlyStepsForToday() async -> [Int] {
        guard isAvailable else { return Array(repeating: 0, count: 24) }

        let startOfDay = calendar.startOfDay(for: Date())
        let now = Date()
        var result = [Int](repeating: 0, count: 24)

        for hour in 0..<24 {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                  let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) else { continue }
            if hourStart >= now { break }
            let end = hourEnd > now ? now : hourEnd
            if let data = await querySteps(from: hourStart, to: end) {
                result[hour] = data.steps
            }
        }
        return result
    }

    /// Son N gün için günlük adım verileri al
    func queryLastDays(_ count: Int) async -> [(date: Date, steps: Int, distance: Double, floorsAscended: Int, floorsDescended: Int)] {
        var results: [(Date, Int, Double, Int, Int)] = []

        for offset in 0..<count {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date

            if let data = await querySteps(from: start, to: end) {
                results.append((date, data.steps, data.distance, data.floorsAscended, data.floorsDescended))
            } else {
                results.append((date, 0, 0, 0, 0))
            }
        }

        return results
    }
}
