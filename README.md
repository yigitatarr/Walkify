# Walkify

A modern iOS step tracking app built with SwiftUI and SwiftData. Track your daily steps, set goals, earn badges, and stay motivated with smart notifications.

## Features

- **Real-time Step Tracking** — Live pedometer data via Core Motion with distance, calories, elevation, and active minutes
- **Daily Goals & Streaks** — Set personalized step goals and build consecutive day streaks
- **Smart Notifications** — Context-aware reminders that adapt based on your progress throughout the day
- **Badges & Achievements** — Earn milestone badges as you hit step targets and maintain streaks
- **Statistics Dashboard** — Visualize your activity with daily, weekly, monthly, and yearly breakdowns
- **Home Screen Widgets** — Glanceable step count widgets for home screen and lock screen
- **HealthKit Integration** — Sync step data from Apple Health for comprehensive tracking
- **Apple Watch Support** — WatchConnectivity integration for paired device status
- **Dark/Light/System Theme** — Adaptive UI with full theme customization
- **Privacy First** — All data stored locally on device, no server or account required

## Screenshots

<img width="200" height="320" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 13 48 35" src="https://github.com/user-attachments/assets/517af4ba-b81d-40bc-925c-3c5a64697763" /> <img width="200" height="320" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 13 48 27" src="https://github.com/user-attachments/assets/622ca3c8-78e4-41be-9683-1cc74ff68a84" /> <img width="200" height="320" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 13 48 19" src="https://github.com/user-attachments/assets/7ed0aeb9-ad25-454c-8697-1fafea067e52" /> <img width="200" height="320" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 13 48 06" src="https://github.com/user-attachments/assets/3bbefece-d6e8-4008-ae19-4f29d3cb1323" /> <img width="200" height="320" alt="Simulator Screenshot - iPhone 17 Pro - 2026-04-10 at 13 47 56" src="https://github.com/user-attachments/assets/af67918d-85d6-456d-874f-00845e175952" />

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData (on-device persistence)
- **Motion**: Core Motion (CMPedometer)
- **Health**: HealthKit (read-only sync)
- **Widgets**: WidgetKit (home screen + lock screen)
- **Watch**: WatchConnectivity
- **Notifications**: UserNotifications (local, context-aware)
- **Architecture**: MVVM with Observable

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yigitatarr/Walkify.git
   ```

2. Open the project in Xcode:
   ```bash
   cd Walkify
   open Walkify.xcodeproj
   ```

3. Configure signing:
   - Select the **Walkify** target → Signing & Capabilities
   - Set your Development Team for both **Walkify** and **WalkifyWidgetExtension** targets
   - Enable **App Groups** capability with identifier `group.com.yigitatar.walkify.yigit`
   - Enable **HealthKit** capability on the main target

4. Build and run on a physical device (pedometer requires real hardware)

## Project Structure

```
Walkify/
├── WalkifyApp.swift              # App entry point & ModelContainer
├── ContentView.swift             # Root view with onboarding & tab routing
├── Models/
│   ├── StepRecord.swift          # Daily step data model
│   ├── UserProfile.swift         # User preferences & profile
│   └── Badge.swift               # Badge type definitions
├── Views/
│   ├── OverviewView.swift        # Main dashboard
│   ├── StatsView.swift           # Performance statistics
│   ├── StepDetailsView.swift     # Detailed step breakdown
│   ├── ProfileView.swift         # Settings & profile
│   ├── OnboardingView.swift      # First-launch setup
│   └── ...                       # Sheet views (Goal, Theme, etc.)
├── Components/
│   ├── MainTabBar.swift          # Custom bottom tab bar
│   ├── MetricCard.swift          # Reusable metric display
│   └── ...
├── Services/
│   ├── StepCounterService.swift  # CMPedometer wrapper
│   ├── StepDataManager.swift     # Data orchestration layer
│   ├── HealthKitManager.swift    # HealthKit integration
│   ├── NotificationService.swift # Smart notification scheduling
│   ├── BadgeChecker.swift        # Achievement evaluation
│   ├── WidgetDataWriter.swift    # Widget data sharing
│   └── ...
├── Theme/
│   └── AppTheme.swift            # Colors, gradients, theming
└── PrivacyInfo.xcprivacy         # Apple privacy manifest

WalkifyWidget/
├── WalkifyWidget.swift           # Widget timeline & views
└── WalkifyWidgetExtension.entitlements
```

## Privacy

Walkify respects user privacy:

- All step and profile data is stored **locally** on the device using SwiftData
- No analytics, tracking, or third-party SDKs
- HealthKit data is read-only and never leaves the device
- Full Apple Privacy Manifest included (`PrivacyInfo.xcprivacy`)

## License

This project is proprietary. All rights reserved.

## Author

**Yiğit Atar** — [GitHub](https://github.com/yigitatarr)
