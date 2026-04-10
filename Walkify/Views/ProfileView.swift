//
//  ProfileView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData
import UIKit

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(StepDataManager.self) private var stepDataManager
    @Environment(WatchConnectionManager.self) private var watchManager
    @Query private var profiles: [UserProfile]
    @State private var showProfileSheet = false
    @State private var showSubscriptionSheet = false
    @State private var showUnitsSheet = false
    @State private var showThemeSheet = false
    @State private var showGoalSheet = false
    @State private var showHealthKitSheet = false
    @State private var showNotificationsSheet = false
    @State private var showBodyProfileSheet = false
    @State private var showWidgetSheet = false
    @State private var showLogoutAlert = false
    @State private var showDeleteDataAlert = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile card
                    profileCard

                    // Settings sections
                    settingsSections

                    // Log out
                    logOutButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNotificationsSheet = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                            Circle()
                                .fill(AppTheme.accentOrange)
                                .frame(width: 8, height: 8)
                                .offset(x: 6, y: -6)
                        }
                    }
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
            .sheet(isPresented: $showUnitsSheet) {
                UnitsSheet(profile: profile) { showUnitsSheet = false }
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showThemeSheet) {
                ThemeSheet(profile: profile) { showThemeSheet = false }
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showGoalSheet) {
                GoalSheet(profile: profile) { showGoalSheet = false }
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileEditSheet(profile: profile) { showProfileSheet = false }
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionSheet(profile: profile) { showSubscriptionSheet = false }
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showHealthKitSheet) {
                HealthKitSheet(onDismiss: { showHealthKitSheet = false })
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsSheet(onDismiss: { showNotificationsSheet = false })
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showBodyProfileSheet) {
                BodyProfileSheet(profile: profile) { showBodyProfileSheet = false }
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showWidgetSheet) {
                WidgetSheet(onDismiss: { showWidgetSheet = false })
                    .presentationDetents([.medium, .large])
            }
            .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
                Button("İptal", role: .cancel) {}
                Button("Çıkış Yap", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Çıkış yapmak istediğinize emin misiniz?")
            }
            .alert("Tüm Verileri Sil", isPresented: $showDeleteDataAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Tüm adım kayıtları, rozetler ve profil bilgilerin kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
        }
    }

    private func performLogout() {
        try? modelContext.save()
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: StepRecord.self)
            try modelContext.delete(model: EarnedBadge.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Delete all data error: \(error)")
            #endif
        }
    }

    private var appVersionFooter: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return Text("Walkify v\(version) (\(build))")
            .font(.system(size: 12))
            .foregroundStyle(AppTheme.textMuted(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    // MARK: - Subviews

    private var profileCard: some View {
        Button { showProfileSheet = true } label: {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    // Profil fotoğrafı veya placeholder
                    ZStack(alignment: .bottomTrailing) {
                        if let data = profile?.avatarImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.accentOrange.opacity(0.35), AppTheme.accentRed.opacity(0.25)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(AppTheme.accentOrange)
                                )
                        }
                        if profile?.isPremium == true {
                            Circle()
                                .fill(AppTheme.premiumGreen)
                                .frame(width: 24, height: 24)
                                .overlay(Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(.white))
                                .overlay(Circle().stroke(AppTheme.cardBackground(for: colorScheme), lineWidth: 2))
                                .offset(x: 2, y: 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text((profile?.name ?? "").isEmpty ? "Kullanıcı" : (profile?.name ?? ""))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                        if profile?.isPremium == true {
                            Text("PREMIUM ÜYE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.premiumGreen))
                        }

                        Text((profile?.email ?? "").isEmpty ? "E-posta eklemek için dokun" : (profile?.email ?? ""))
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                }

                // Özet bilgiler
                HStack(spacing: 16) {
                    profileSummaryChip(icon: "flag.fill", value: "\(profile?.dailyStepGoal ?? 10000)", label: "Günlük hedef")
                    if let p = profile, p.weightKg > 0, p.heightCm > 0 {
                        profileSummaryChip(icon: "figure.stand", value: "\(Int(p.heightCm)) cm", label: "Boy")
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func profileSummaryChip(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.accentOrange)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
        )
    }

    private var settingsSections: some View {
        VStack(alignment: .leading, spacing: 28) {
            SettingsSectionView(title: "HESAP") {
                SettingsRow(icon: "person.fill", iconColor: .pink, title: "Profil", action: { showProfileSheet = true })
                SettingsRowDivider()
                SettingsRow(icon: "creditcard.fill", iconColor: AppTheme.accentOrange, title: "Abonelik", action: { showSubscriptionSheet = true })
            }

            SettingsSectionView(title: "UYGULAMA") {
                SettingsToggleRow(icon: "figure.walk", iconColor: AppTheme.accentOrange, title: "Adım Sayacı", isOn: Binding(
                    get: { !(profile?.isStepTrackingPaused ?? false) },
                    set: {
                        profile?.isStepTrackingPaused = !$0
                        try? modelContext.save()
                        if profile?.isStepTrackingPaused == true {
                            stepDataManager.stopLiveUpdates()
                        } else {
                            stepDataManager.startLiveUpdates()
                            Task {
                                await stepDataManager.syncHistoricalData()
                            }
                        }
                    }
                ))
                SettingsRowDivider()
                SettingsRow(icon: "figure.stand", iconColor: AppTheme.accentOrange, title: "Vücut Profili", subtitle: bodyProfileSubtitle, action: { showBodyProfileSheet = true })
                SettingsRowDivider()
                SettingsRow(icon: "flag.fill", iconColor: AppTheme.accentOrange, title: "Günlük Hedef", subtitle: "\(profile?.dailyStepGoal ?? 10000) adım", action: { showGoalSheet = true })
                SettingsRowDivider()
                SettingsToggleRow(icon: "bell.fill", iconColor: AppTheme.success, title: "Bildirimler", isOn: Binding(
                    get: { profile?.notificationsEnabled ?? true },
                    set: { newValue in
                        profile?.notificationsEnabled = newValue
                        try? modelContext.save()
                    }
                ))
                SettingsRowDivider()
                SettingsRow(icon: "ruler.fill", iconColor: AppTheme.accentOrange, title: "Birimler", subtitle: (profile?.useMetricUnits ?? true) ? "Metrik" : "İngiliz", action: { showUnitsSheet = true })
                SettingsRowDivider()
                SettingsRow(icon: "moon.fill", iconColor: .purple, title: "Tema", subtitle: themeSubtitle, action: { showThemeSheet = true })
            }

            SettingsSectionView(title: "ANA EKRAN") {
                SettingsRow(icon: "square.grid.2x2.fill", iconColor: AppTheme.accentOrange, title: "Widget Ekle", subtitle: "Ana ekranda adım sayını gör", action: { showWidgetSheet = true })
            }

            SettingsSectionView(title: "CİHAZLAR") {
                SettingsRow(icon: "applewatch", iconColor: AppTheme.accentOrange, title: "Apple Watch", subtitle: watchManager.connectionStatus, subtitleColor: watchManager.isReachable ? AppTheme.success : AppTheme.textSecondary, action: { watchManager.updateStatus() })
                SettingsRowDivider()
                SettingsRow(icon: "heart.fill", iconColor: AppTheme.success, title: "HealthKit", action: { showHealthKitSheet = true })
            }

            SettingsSectionView(title: "DESTEK") {
                SettingsRow(icon: "questionmark.circle.fill", iconColor: .pink, title: "Yardım Merkezi", action: { openURL("https://support.apple.com") })
                SettingsRowDivider()
                SettingsRow(icon: "shield.fill", iconColor: AppTheme.accentOrange, title: "Gizlilik Politikası", showLink: true, action: { openURL("https://sites.google.com/view/walkify-privacy") })
                SettingsRowDivider()
                SettingsRow(icon: "doc.text.fill", iconColor: .blue, title: "Kullanım Koşulları", showLink: true, action: { openURL("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") })
            }

            SettingsSectionView(title: "VERİ") {
                SettingsRow(icon: "trash.fill", iconColor: AppTheme.error, title: "Tüm Verileri Sil", action: { showDeleteDataAlert = true })
            }

            appVersionFooter
        }
    }

    private var bodyProfileSubtitle: String {
        guard let p = profile, p.weightKg > 0, p.heightCm > 0 else { return "Ayarlanmadı" }
        return "\(Int(p.weightKg)) kg, \(Int(p.heightCm)) cm"
    }

    private var themeSubtitle: String {
        switch profile?.themePreference ?? "dark" {
        case "light": return "Açık"
        case "dark": return "Koyu"
        default: return "Sistem"
        }
    }

    private var logOutButton: some View {
        Button { showLogoutAlert = true } label: {
            Text("Çıkış Yap")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.6), lineWidth: 1)
        )
        .buttonStyle(.plain)
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Settings Section

struct SettingsSectionView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme).opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Row Divider

struct SettingsRowDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Rectangle()
            .fill(AppTheme.cardBackgroundSecondary(for: colorScheme))
            .frame(height: 0.5)
            .padding(.leading, 68)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var subtitleColor: Color = Color.gray
    var showLink: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                Spacer(minLength: 8)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(subtitleColor)
                        .lineLimit(1)
                }

                if showLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .tint(AppTheme.accentOrange)
                .labelsHidden()
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
