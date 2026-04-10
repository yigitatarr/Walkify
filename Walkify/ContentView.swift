//
//  ContentView.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(StepDataManager.self) private var stepDataManager
    @Query private var profiles: [UserProfile]
    @State private var selectedTab: TabItem = .overview
    @State private var onboardingCompleted = false

    private var needsOnboarding: Bool {
        guard let profile = profiles.first else { return true }
        return !profile.hasCompletedOnboarding
    }

    /// Kullanıcı tema tercihi (preferredColorScheme için)
    private var themeColorScheme: ColorScheme? {
        switch profiles.first?.themePreference ?? "dark" {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    /// Arka plan rengi için: light/dark doğrudan, system = cihaz ayarı
    private var resolvedColorScheme: ColorScheme {
        switch profiles.first?.themePreference ?? "dark" {
        case "light": return .light
        case "dark": return .dark
        default: return colorScheme
        }
    }

    var body: some View {
        Group {
            if needsOnboarding && !onboardingCompleted {
                OnboardingView(isCompleted: $onboardingCompleted)
            } else {
                mainContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background(for: resolvedColorScheme))
        .ignoresSafeArea()
        .preferredColorScheme(needsOnboarding ? .dark : themeColorScheme)
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .overview:
                    OverviewView()
                case .stats:
                    StatsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3-tab bottom bar
            VStack {
                Spacer()
                MainTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(AppTheme.background(for: resolvedColorScheme))
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            stepDataManager.configure(modelContext: modelContext)
            if !(profiles.first?.isStepTrackingPaused ?? false) {
                stepDataManager.startLiveUpdates()
                Task {
                    await stepDataManager.syncHistoricalData()
                }
            } else {
                stepDataManager.stopLiveUpdates()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(StepDataManager())
        .environment(WatchConnectionManager())
        .modelContainer(for: [StepRecord.self, UserProfile.self, EarnedBadge.self], inMemory: true)
}
