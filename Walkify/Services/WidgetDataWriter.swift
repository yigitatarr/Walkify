//
//  WidgetDataWriter.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import WidgetKit

enum WidgetDataWriter {
    static let appGroupID = "group.com.yigitatar.walkify.yigit"

    static var userDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    static func write(
        steps: Int,
        goal: Int,
        distance: Double,
        calories: Int,
        useMetric: Bool,
        currentStreak: Int = 0,
        daysReachedThisWeek: Int = 0
    ) {
        userDefaults?.set(steps, forKey: "steps")
        userDefaults?.set(goal, forKey: "goal")
        userDefaults?.set(distance, forKey: "distance")
        userDefaults?.set(calories, forKey: "calories")
        userDefaults?.set(useMetric, forKey: "useMetric")
        userDefaults?.set(currentStreak, forKey: "currentStreak")
        userDefaults?.set(daysReachedThisWeek, forKey: "daysReachedThisWeek")
        userDefaults?.set(Date(), forKey: "lastUpdated")
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
