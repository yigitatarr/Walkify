//
//  OnboardingView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isCompleted: Bool

    @State private var currentStep = 0
    @State private var name = ""
    @State private var weightKg: Double = 70
    @State private var heightCm: Double = 170
    @State private var stepLengthCm: Double = 0 // 0 = boydan hesapla
    @State private var useCustomStepLength = false

    private var calculatedStepLength: Double { heightCm * 0.415 }

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Progress
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(AppTheme.cardBackgroundSecondary(for: colorScheme)))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Content
                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        bodyProfileStep
                    case 2:
                        stepLengthStep
                    case 3:
                        completeStep
                    default:
                        welcomeStep
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Geri") {
                            withAnimation { currentStep -= 1 }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    Button(currentStep == 3 ? "Başla" : "İleri") {
                        if currentStep == 3 {
                            completeOnboarding()
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.accentGradient)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accentOrange)

            Text("Walkify'e Hoş Geldin!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("Daha doğru hesaplamalar için birkaç bilgi verir misin?")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Adınız", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
    }

    private var bodyProfileStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accentOrange)

            Text("Vücut Ölçülerin")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text("Mesafe ve kalori hesaplaması için gerekli")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kilo (kg)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    HStack {
                        Text("\(Int(weightKg))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                            .frame(width: 50)
                        Slider(value: $weightKg, in: 30...150, step: 1)
                            .tint(AppTheme.accentOrange)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Boy (cm)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    HStack {
                        Text("\(Int(heightCm))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                            .frame(width: 50)
                        Slider(value: $heightCm, in: 100...220, step: 1)
                            .tint(AppTheme.accentOrange)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private var stepLengthStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "ruler")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accentOrange)

            Text("Adım Uzunluğu")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text("Boyundan hesaplanan: \(String(format: "%.0f", calculatedStepLength)) cm")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

            Toggle("Özel değer kullan", isOn: $useCustomStepLength)
                .tint(AppTheme.accentOrange)
                .padding(.horizontal, 24)

            if useCustomStepLength {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adım uzunluğu (cm)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    HStack {
                        Text("\(Int(stepLengthCm == 0 ? calculatedStepLength : stepLengthCm))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                            .frame(width: 50)
                        Slider(value: Binding(
                            get: { stepLengthCm == 0 ? calculatedStepLength : stepLengthCm },
                            set: { stepLengthCm = $0 }
                        ), in: 50...120, step: 1)
                        .tint(AppTheme.accentOrange)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                )
                .padding(.horizontal, 24)
            }
        }
    }

    private var completeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.success)

            Text("Hazırsın!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Text(previewText)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var previewText: String {
        let stepLen = useCustomStepLength && stepLengthCm > 0 ? stepLengthCm : calculatedStepLength
        let dist = ActivityCalculator.distanceFromSteps(10000, stepLengthCm: stepLen)
        let cal = ActivityCalculator.caloriesFromDistance(distanceKm: dist, weightKg: weightKg)
        return "Örnek: 10.000 adımda yaklaşık \(String(format: "%.2f", dist)) km ve \(cal) kcal yakacaksın."
    }

    private func completeOnboarding() {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? modelContext.fetch(descriptor))?.first

        if let profile = existing {
            profile.name = name.isEmpty ? "Kullanıcı" : name
            profile.weightKg = weightKg
            profile.heightCm = heightCm
            profile.stepLengthCm = useCustomStepLength && stepLengthCm > 0 ? stepLengthCm : nil
            profile.hasCompletedOnboarding = true
        } else {
            let profile = UserProfile(
                name: name.isEmpty ? "Kullanıcı" : name,
                email: "",
                isPremium: false,
                dailyStepGoal: 10000,
                useMetricUnits: true,
                notificationsEnabled: true,
                themePreference: "dark",
                weightKg: weightKg,
                heightCm: heightCm,
                stepLengthCm: useCustomStepLength && stepLengthCm > 0 ? stepLengthCm : nil,
                hasCompletedOnboarding: true
            )
            modelContext.insert(profile)
        }
        try? modelContext.save()
        isCompleted = true
    }
}
