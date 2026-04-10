//
//  ActivityCalculator.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation

/// Kilo, boy ve adım uzunluğuna göre mesafe ve kalori hesaplar
enum ActivityCalculator {

    // MARK: - Mesafe Hesaplama

    /// Adımlardan mesafe hesapla (km)
    /// - steps: Adım sayısı
    /// - stepLengthCm: Adım uzunluğu (cm), nil ise varsayılan 76 cm kullanılır
    static func distanceFromSteps(_ steps: Int, stepLengthCm: Double? = nil) -> Double {
        let length = stepLengthCm ?? 76 // Ortalama yetişkin adım uzunluğu
        return Double(steps) * (length / 100_000) // cm → km
    }

    /// Profil ile mesafe hesapla
    static func distanceFromSteps(_ steps: Int, profile: UserProfile?) -> Double {
        let stepLength = profile?.effectiveStepLengthCm ?? 76
        return distanceFromSteps(steps, stepLengthCm: stepLength)
    }

    // MARK: - Kalori Hesaplama

    /// Yürüyüş için kalori hesapla
    /// Formül: 0.57 × kilo(kg) × mesafe(km) - yavaş/orta tempo yürüyüş için
    /// Kaynak: ACSM (American College of Sports Medicine) yürüyüş metabolik denklemi
    static func caloriesFromDistance(distanceKm: Double, weightKg: Double) -> Int {
        guard weightKg > 0 else {
            return Int(distanceKm * 50) // Varsayılan ~70 kg için fallback
        }
        return Int(0.57 * weightKg * distanceKm)
    }

    /// Adım ve profil ile kalori hesapla (önce mesafe, sonra kalori)
    static func caloriesFromSteps(_ steps: Int, profile: UserProfile?) -> Int {
        let distance = distanceFromSteps(steps, profile: profile)
        let weight = profile?.weightKg ?? 70
        return caloriesFromDistance(distanceKm: distance, weightKg: weight)
    }

    /// Tek satırda mesafe + kalori
    static func distanceAndCalories(from steps: Int, profile: UserProfile?) -> (distance: Double, calories: Int) {
        let distance = distanceFromSteps(steps, profile: profile)
        let calories = caloriesFromDistance(distanceKm: distance, weightKg: profile?.weightKg ?? 70)
        return (distance, calories)
    }
}
