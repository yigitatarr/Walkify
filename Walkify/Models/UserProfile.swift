//
//  UserProfile.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var email: String
    var isPremium: Bool
    var dailyStepGoal: Int
    var useMetricUnits: Bool
    var notificationsEnabled: Bool
    var themePreference: String // "light", "dark", "system"
    var avatarImageData: Data?

    // Vücut profili (mesafe ve kalori hesaplaması için)
    var weightKg: Double
    var heightCm: Double
    var stepLengthCm: Double? // Boşsa boydan hesaplanır

    // Onboarding tamamlandı mı?
    var hasCompletedOnboarding: Bool

    // Adım sayacı duraklatıldı mı?
    var isStepTrackingPaused: Bool

    init(
        name: String = "",
        email: String = "",
        isPremium: Bool = false,
        dailyStepGoal: Int = 10000,
        useMetricUnits: Bool = true,
        notificationsEnabled: Bool = true,
        themePreference: String = "dark",
        weightKg: Double = 0,
        heightCm: Double = 0,
        stepLengthCm: Double? = nil,
        hasCompletedOnboarding: Bool = false,
        isStepTrackingPaused: Bool = false,
        avatarImageData: Data? = nil
    ) {
        self.name = name
        self.email = email
        self.isPremium = isPremium
        self.dailyStepGoal = dailyStepGoal
        self.useMetricUnits = useMetricUnits
        self.notificationsEnabled = notificationsEnabled
        self.themePreference = themePreference
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.stepLengthCm = stepLengthCm
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isStepTrackingPaused = isStepTrackingPaused
        self.avatarImageData = avatarImageData
    }

    /// Adım uzunluğu (cm) - özel değer yoksa boydan hesaplanır
    var effectiveStepLengthCm: Double {
        if let custom = stepLengthCm, custom > 0 {
            return custom
        }
        // Boydan tahmini: ortalama adım uzunluğu ≈ boyun %41.5'i
        return heightCm > 0 ? heightCm * 0.415 : 76 // Varsayılan 76 cm
    }
}
