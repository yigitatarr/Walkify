//
//  Badge.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import SwiftData

enum BadgeType: String, Codable, CaseIterable {
    case firstSteps = "first_steps"
    case thousandSteps = "thousand_steps"
    case fiveThousand = "five_thousand"
    case tenThousand = "ten_thousand"
    case fifteenThousand = "fifteen_thousand"
    case twentyThousand = "twenty_thousand"
    case weekStreak = "week_streak"
    case twoWeekStreak = "two_week_streak"
    case monthStreak = "month_streak"
    case hundredKm = "hundred_km"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"

    var title: String {
        switch self {
        case .firstSteps: return "İlk Adımlar"
        case .thousandSteps: return "1.000 Adım"
        case .fiveThousand: return "5.000 Adım"
        case .tenThousand: return "10.000 Adım"
        case .fifteenThousand: return "15.000 Adım"
        case .twentyThousand: return "20.000 Adım"
        case .weekStreak: return "7 Gün Serisi"
        case .twoWeekStreak: return "14 Gün Serisi"
        case .monthStreak: return "30 Gün Serisi"
        case .hundredKm: return "100 km"
        case .earlyBird: return "Erken Kuş"
        case .nightOwl: return "Gece Kuşu"
        }
    }

    var icon: String {
        switch self {
        case .firstSteps: return "figure.walk"
        case .thousandSteps: return "1.circle.fill"
        case .fiveThousand: return "5.circle.fill"
        case .tenThousand: return "star.fill"
        case .fifteenThousand: return "15.circle.fill"
        case .twentyThousand: return "flame.fill"
        case .weekStreak: return "flame.circle.fill"
        case .twoWeekStreak: return "flame.circle.fill"
        case .monthStreak: return "crown.fill"
        case .hundredKm: return "map.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        }
    }

    var description: String {
        switch self {
        case .firstSteps: return "İlk yürüyüşüne başladın"
        case .thousandSteps: return "1.000 adım attın"
        case .fiveThousand: return "5.000 adım hedefi"
        case .tenThousand: return "10.000 adım hedefi"
        case .fifteenThousand: return "15.000 adım hedefi"
        case .twentyThousand: return "20.000 adım hedefi"
        case .weekStreak: return "7 gün üst üste hedef"
        case .twoWeekStreak: return "14 gün üst üste hedef"
        case .monthStreak: return "30 gün üst üste hedef"
        case .hundredKm: return "Toplam 100 km yürüdün"
        case .earlyBird: return "Sabah 7'den önce 5.000 adım"
        case .nightOwl: return "Akşam 10'dan sonra 5.000 adım"
        }
    }
}

@Model
final class EarnedBadge {
    var badgeType: String
    var earnedAt: Date

    init(badgeType: BadgeType, earnedAt: Date = .now) {
        self.badgeType = badgeType.rawValue
        self.earnedAt = earnedAt
    }

    var type: BadgeType? { BadgeType(rawValue: badgeType) }
}
