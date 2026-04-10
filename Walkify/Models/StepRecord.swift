//
//  StepRecord.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import SwiftData

@Model
final class StepRecord {
    var date: Date
    var steps: Int
    var distance: Double // km
    var calories: Int
    var activeMinutes: Int
    var floorsAscended: Int
    var floorsDescended: Int

    init(
        date: Date = .now,
        steps: Int = 0,
        distance: Double = 0,
        calories: Int = 0,
        activeMinutes: Int = 0,
        floorsAscended: Int = 0,
        floorsDescended: Int = 0
    ) {
        self.date = date
        self.steps = steps
        self.distance = distance
        self.calories = calories
        self.activeMinutes = activeMinutes
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
    }

    var elevationGainMeters: Double { Double(floorsAscended) * 3.0 }
}
