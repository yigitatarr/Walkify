//
//  WalkifyWidget.swift
//  WalkifyWidget
//
//  Created by Yiğit on 25.02.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Colors (static to avoid re-allocation)

private enum WColors {
    static let accent = Color(red: 1, green: 0.42, blue: 0.21)
    static let cardBg = Color(red: 0.1, green: 0.1, blue: 0.11)
    static let secondary = Color(red: 0.61, green: 0.61, blue: 0.64)
}

// MARK: - Lightweight Progress Bar (replaces ProgressView + scaleEffect + LinearGradient)

private struct ProgressBar: View {
    let progress: Double
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(WColors.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(WColors.accent)
                    .frame(width: geo.size.width * min(1, max(0, progress)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Data

struct WidgetData {
    let steps: Int
    let goal: Int
    let distance: Double
    let calories: Int
    let useMetric: Bool
    let lastUpdated: Date?
    let currentStreak: Int
    let daysReachedThisWeek: Int

    static let appGroupID = "group.com.yigitatar.walkify.yigit"

    static func load() -> WidgetData? {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return nil }
        let steps = ud.integer(forKey: "steps")
        let goal = ud.integer(forKey: "goal")
        if goal == 0 { return nil }
        return WidgetData(
            steps: steps,
            goal: goal,
            distance: ud.double(forKey: "distance"),
            calories: ud.integer(forKey: "calories"),
            useMetric: ud.object(forKey: "useMetric") as? Bool ?? true,
            lastUpdated: ud.object(forKey: "lastUpdated") as? Date,
            currentStreak: ud.integer(forKey: "currentStreak"),
            daysReachedThisWeek: ud.integer(forKey: "daysReachedThisWeek")
        )
    }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(steps) / Double(goal))
    }

    var stepsRemaining: Int { max(0, goal - steps) }
    var progressPercent: Int { goal > 0 ? min(100, Int(progress * 100)) : 0 }

    var distanceText: String {
        if useMetric {
            return String(format: "%.1f km", distance)
        } else {
            return String(format: "%.1f mi", distance / 1.609)
        }
    }

    var lastUpdatedShort: String {
        guard let t = lastUpdated else { return "" }
        let m = Int(-t.timeIntervalSinceNow / 60)
        if m < 1 { return "Az önce" }
        if m < 60 { return "\(m) dk önce" }
        let h = m / 60
        return "\(h) sa önce"
    }
}

// MARK: - Timeline

struct WalkifyWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
}

struct WalkifyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WalkifyWidgetEntry {
        WalkifyWidgetEntry(date: .now, data: WidgetData(
            steps: 5420, goal: 10000, distance: 4.1, calories: 220,
            useMetric: true, lastUpdated: .now, currentStreak: 3, daysReachedThisWeek: 4
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (WalkifyWidgetEntry) -> Void) {
        completion(WalkifyWidgetEntry(date: .now, data: WidgetData.load() ?? placeholder(in: context).data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WalkifyWidgetEntry>) -> Void) {
        let now = Date()
        let entry = WalkifyWidgetEntry(date: now, data: WidgetData.load())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Entry View

struct WalkifyWidgetEntryView: View {
    var entry: WalkifyWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let data = entry.data {
            switch family {
            case .systemSmall:      SmallWidgetView(data: data)
            case .systemMedium:     MediumWidgetView(data: data)
            case .systemLarge:      LargeWidgetView(data: data)
            case .accessoryCircular:     AccessoryCircularView(data: data)
            case .accessoryRectangular:  AccessoryRectangularView(data: data)
            case .accessoryInline:       AccessoryInlineView(data: data)
            default:                SmallWidgetView(data: data)
            }
        } else {
            switch family {
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                AccessoryEmptyView(family: family)
            default:
                EmptyWidgetView()
            }
        }
    }
}

// MARK: - Small

struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14))
                    .foregroundStyle(WColors.accent)
                Text("Walkify")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WColors.secondary)
                if data.currentStreak > 0 {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(WColors.accent)
                        Text("\(data.currentStreak)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            Spacer()
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(data.steps)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                Text("/ \(data.goal)")
                    .font(.system(size: 12))
                    .foregroundStyle(WColors.secondary)
            }
            Text("adım bugün")
                .font(.system(size: 11))
                .foregroundStyle(WColors.secondary)
            if data.stepsRemaining > 0 {
                Text("\(data.stepsRemaining) adım kaldı")
                    .font(.system(size: 10))
                    .foregroundStyle(WColors.secondary.opacity(0.9))
            }
            ProgressBar(progress: data.progress, height: 4)
        }
        .padding(16)
        .containerBackground(WColors.cardBg, for: .widget)
    }
}

// MARK: - Medium

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 16))
                    .foregroundStyle(WColors.accent)
                Text("Walkify")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WColors.secondary)
                if data.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(WColors.accent)
                        Text("\(data.currentStreak) gün seri")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(WColors.accent.opacity(0.25)))
                }
            }
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(data.steps)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text("/ \(data.goal) hedef • %\(data.progressPercent)")
                        .font(.system(size: 12))
                        .foregroundStyle(WColors.secondary)
                    if data.stepsRemaining > 0 {
                        Text("\(data.stepsRemaining) adım kaldı")
                            .font(.system(size: 11))
                            .foregroundStyle(WColors.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(data.distanceText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text("mesafe")
                            .font(.system(size: 10))
                            .foregroundStyle(WColors.secondary)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(data.calories)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text("kalori")
                            .font(.system(size: 10))
                            .foregroundStyle(WColors.secondary)
                    }
                }
            }
            ProgressBar(progress: data.progress, height: 5)
        }
        .padding(20)
        .containerBackground(WColors.cardBg, for: .widget)
    }
}

// MARK: - Large

struct LargeWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 20))
                    .foregroundStyle(WColors.accent)
                Text("Walkify")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                if data.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(WColors.accent)
                        Text("\(data.currentStreak) gün seri")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(WColors.accent.opacity(0.25)))
                }
                Spacer()
                if !data.lastUpdatedShort.isEmpty {
                    Text(data.lastUpdatedShort)
                        .font(.system(size: 11))
                        .foregroundStyle(WColors.secondary.opacity(0.8))
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("\(data.steps) / \(data.goal)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text("adım bugün • %\(data.progressPercent)")
                    .font(.system(size: 14))
                    .foregroundStyle(WColors.secondary)
                if data.stepsRemaining > 0 {
                    Text("\(data.stepsRemaining) adım kaldı")
                        .font(.system(size: 13))
                        .foregroundStyle(WColors.accent)
                }
                ProgressBar(progress: data.progress, height: 6)
            }
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.distanceText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Mesafe")
                        .font(.system(size: 12))
                        .foregroundStyle(WColors.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(data.calories)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Kalori")
                        .font(.system(size: 12))
                        .foregroundStyle(WColors.secondary)
                }
                if data.daysReachedThisWeek > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(data.daysReachedThisWeek)/7")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Bu hafta hedef")
                            .font(.system(size: 12))
                            .foregroundStyle(WColors.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .containerBackground(WColors.cardBg, for: .widget)
    }
}

// MARK: - Empty State

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 32))
                .foregroundStyle(WColors.secondary.opacity(0.5))
            Text("Walkify'ı aç")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WColors.secondary)
            Text("Adım verilerin görünsün")
                .font(.system(size: 12))
                .foregroundStyle(WColors.secondary.opacity(0.8))
        }
        .containerBackground(WColors.cardBg, for: .widget)
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    let data: WidgetData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(data.progress))
                .stroke(WColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(data.steps)")
                    .font(.system(size: 14, weight: .bold))
                    .minimumScaleFactor(0.6)
                Image(systemName: "figure.walk")
                    .font(.system(size: 8))
            }
            .widgetAccentable()
        }
    }
}

struct AccessoryRectangularView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                Text("Walkify")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(WColors.accent)
            Text("\(data.steps) / \(data.goal) adım")
                .font(.system(size: 18, weight: .bold))
            Text("\(data.distanceText) • \(data.calories) kcal")
                .font(.system(size: 11))
                .foregroundStyle(WColors.secondary)
            if data.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(data.currentStreak) gün seri")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(WColors.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct AccessoryInlineView: View {
    let data: WidgetData

    var body: some View {
        Text("\(data.steps.formatted()) adım • %\(data.progressPercent)")
    }
}

struct AccessoryEmptyView: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "figure.walk")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.gray.opacity(0.7))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text("Walkify")
                    .font(.system(size: 12, weight: .semibold))
                Text("Uygulamayı aç, adım verilerin yüklensin")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        case .accessoryInline:
            Text("Walkify – uygulamayı aç")
        default:
            EmptyView()
        }
    }
}

// MARK: - Widget

@main
struct WalkifyWidget: Widget {
    let kind: String = "WalkifyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WalkifyWidgetProvider()) { entry in
            WalkifyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Walkify")
        .description("Adım sayısı, hedef, seri ve haftalık özet. Ana ekran ve kilit ekranı.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

#Preview(as: .systemSmall) {
    WalkifyWidget()
} timeline: {
    WalkifyWidgetEntry(date: .now, data: WidgetData(
        steps: 5420, goal: 10000, distance: 4.1, calories: 220,
        useMetric: true, lastUpdated: .now, currentStreak: 3, daysReachedThisWeek: 4
    ))
}
