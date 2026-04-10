//
//  WidgetSheet.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI
import WidgetKit

struct WidgetSheet: View {
    let onDismiss: () -> Void
    @State private var selectedWidget: WidgetType? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ana ekran widget'ları")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        ForEach(WidgetType.homeScreenWidgets, id: \.self) { type in
                            WidgetOptionCard(
                                type: type,
                                isSelected: selectedWidget == type,
                                colorScheme: colorScheme
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedWidget = selectedWidget == type ? nil : type
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kilit ekranı widget'ları")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        ForEach(WidgetType.lockScreenWidgets, id: \.self) { type in
                            WidgetOptionCard(
                                type: type,
                                isSelected: selectedWidget == type,
                                colorScheme: colorScheme
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedWidget = selectedWidget == type ? nil : type
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nasıl eklenir?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                        VStack(alignment: .leading, spacing: 12) {
                            InstructionStep(number: 1, text: "Ana ekranda boş bir alana uzun bas", colorScheme: colorScheme)
                            InstructionStep(number: 2, text: "Sol üstteki \"+\" butonuna dokun", colorScheme: colorScheme)
                            InstructionStep(number: 3, text: "\"Walkify\"ı bul ve seç", colorScheme: colorScheme)
                            InstructionStep(number: 4, text: "Küçük, Orta veya Büyük boy seç", colorScheme: colorScheme)
                            InstructionStep(number: 5, text: "\"Widget Ekle\"ye dokun", colorScheme: colorScheme)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.cardBackground(for: colorScheme))
                        )
                    }

                    Button {
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Widget'ları Güncelle")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AnyShapeStyle(AppTheme.accentGradient))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .padding(.bottom, 20)
            }
            .background(AppTheme.background(for: colorScheme))
            .navigationTitle("Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.accentOrange)
                }
            }
            .toolbarBackground(AppTheme.background(for: colorScheme), for: .navigationBar)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.accentOrange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ana Sayfa Widget'ı")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Text("Adım, seri ve haftalık özeti ana ekranda veya kilit ekranında gör")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        )
    }
}

// MARK: - Widget Types

enum WidgetType: String, CaseIterable, Hashable {
    case small, medium, large
    case circular, rectangular, inline

    static var homeScreenWidgets: [WidgetType] { [.small, .medium, .large] }
    static var lockScreenWidgets: [WidgetType] { [.circular, .rectangular, .inline] }

    var title: String {
        switch self {
        case .small: return "Küçük"
        case .medium: return "Orta"
        case .large: return "Büyük"
        case .circular: return "Dairesel"
        case .rectangular: return "Dikdörtgen"
        case .inline: return "Satır"
        }
    }

    var description: String {
        switch self {
        case .small: return "Adım, hedef, kalan adım ve seri (🔥)"
        case .medium: return "Adım, mesafe, kalori, % ilerleme ve seri"
        case .large: return "Tüm detaylar, bu hafta hedef (X/7) ve son güncelleme"
        case .circular: return "İlerleme halkası ve adım sayısı"
        case .rectangular: return "Adım, mesafe, kalori ve seri"
        case .inline: return "Kısa özet: \"5.420 adım • %54\""
        }
    }

    var icon: String {
        switch self {
        case .small: return "square.fill"
        case .medium: return "rectangle.fill"
        case .large: return "rectangle.expand.vertical.fill"
        case .circular: return "circle.fill"
        case .rectangular: return "rectangle.fill"
        case .inline: return "text.line.first.and.arrowtriangle.forward"
        }
    }

    var previewSize: CGSize {
        switch self {
        case .small: return CGSize(width: 170, height: 170)
        case .medium: return CGSize(width: 340, height: 170)
        case .large: return CGSize(width: 340, height: 340)
        case .circular: return CGSize(width: 76, height: 76)
        case .rectangular: return CGSize(width: 170, height: 76)
        case .inline: return CGSize(width: 200, height: 24)
        }
    }
}

// MARK: - Widget Option Card

private struct WidgetOptionCard: View {
    let type: WidgetType
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    private let sampleData = SampleWidgetData(
        steps: 5420, goal: 10000, distance: 4.1,
        calories: 220, streak: 3, daysReached: 4, progress: 0.54
    )

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : AppTheme.accentOrange)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? AppTheme.accentOrange : AppTheme.accentOrange.opacity(0.2))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Text(type.description)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    Spacer()
                    Image(systemName: isSelected ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? AppTheme.accentOrange : AppTheme.textSecondary(for: colorScheme).opacity(0.5))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isSelected {
                VStack(spacing: 16) {
                    Divider()
                        .background(AppTheme.textMuted(for: colorScheme).opacity(0.3))

                    GeometryReader { geo in
                        widgetPreview
                            .frame(
                                width: min(type.previewSize.width, geo.size.width),
                                height: type.previewSize.height
                            )
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: type.previewSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: type == .circular ? 38 : 16))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                    Text("Widget önizlemesi")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? AppTheme.accentOrange.opacity(0.5) : .clear, lineWidth: 1.5)
                )
        )
    }

    @ViewBuilder
    private var widgetPreview: some View {
        switch type {
        case .small:
            SmallWidgetPreview(data: sampleData)
        case .medium:
            MediumWidgetPreview(data: sampleData)
        case .large:
            LargeWidgetPreview(data: sampleData)
        case .circular:
            CircularWidgetPreview(data: sampleData)
        case .rectangular:
            RectangularWidgetPreview(data: sampleData)
        case .inline:
            InlineWidgetPreview(data: sampleData)
        }
    }
}

// MARK: - Sample Data

struct SampleWidgetData {
    let steps: Int
    let goal: Int
    let distance: Double
    let calories: Int
    let streak: Int
    let daysReached: Int
    let progress: Double

    var stepsRemaining: Int { max(0, goal - steps) }
    var progressPercent: Int { Int(progress * 100) }
    var distanceText: String { String(format: "%.1f km", distance) }
}

// MARK: - Widget Previews

private struct SmallWidgetPreview: View {
    let data: SampleWidgetData
    private let bg = Color(red: 0.1, green: 0.1, blue: 0.11)
    private let accent = Color(red: 1, green: 0.42, blue: 0.21)
    private let secondary = Color(red: 0.61, green: 0.61, blue: 0.64)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                    .foregroundStyle(accent)
                Text("Walkify")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(secondary)
                if data.streak > 0 {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(accent)
                        Text("\(data.streak)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            Spacer()
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(data.steps)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("/ \(data.goal)")
                    .font(.system(size: 10))
                    .foregroundStyle(secondary)
            }
            Text("\(data.stepsRemaining) adım kaldı")
                .font(.system(size: 9))
                .foregroundStyle(secondary)
            ProgressView(value: data.progress)
                .tint(LinearGradient(colors: [accent, .red], startPoint: .leading, endPoint: .trailing))
                .scaleEffect(y: 1.5, anchor: .center)
        }
        .padding(14)
        .background(bg)
    }
}

private struct MediumWidgetPreview: View {
    let data: SampleWidgetData
    private let bg = Color(red: 0.1, green: 0.1, blue: 0.11)
    private let accent = Color(red: 1, green: 0.42, blue: 0.21)
    private let secondary = Color(red: 0.61, green: 0.61, blue: 0.64)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                    .foregroundStyle(accent)
                Text("Walkify")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(secondary)
                if data.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(accent)
                        Text("\(data.streak) gün")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(accent.opacity(0.25)))
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(data.steps)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text("/ \(data.goal) • %\(data.progressPercent)")
                        .font(.system(size: 9))
                        .foregroundStyle(secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(data.distanceText)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text("mesafe")
                            .font(.system(size: 8))
                            .foregroundStyle(secondary)
                    }
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(data.calories)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text("kalori")
                            .font(.system(size: 8))
                            .foregroundStyle(secondary)
                    }
                }
            }
            ProgressView(value: data.progress)
                .tint(LinearGradient(colors: [accent, .red], startPoint: .leading, endPoint: .trailing))
                .scaleEffect(y: 2, anchor: .center)
        }
        .padding(14)
        .background(bg)
    }
}

private struct LargeWidgetPreview: View {
    let data: SampleWidgetData
    private let bg = Color(red: 0.1, green: 0.1, blue: 0.11)
    private let accent = Color(red: 1, green: 0.42, blue: 0.21)
    private let secondary = Color(red: 0.61, green: 0.61, blue: 0.64)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14))
                    .foregroundStyle(accent)
                Text("Walkify")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                if data.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(accent)
                        Text("\(data.streak) gün")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(accent.opacity(0.25)))
                }
                Spacer()
                Text("Az önce")
                    .font(.system(size: 9))
                    .foregroundStyle(secondary.opacity(0.8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(data.steps) / \(data.goal)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("adım bugün • %\(data.progressPercent)")
                    .font(.system(size: 11))
                    .foregroundStyle(secondary)
                Text("\(data.stepsRemaining) adım kaldı")
                    .font(.system(size: 10))
                    .foregroundStyle(accent)
                ProgressView(value: data.progress)
                    .tint(LinearGradient(colors: [accent, .red], startPoint: .leading, endPoint: .trailing))
                    .scaleEffect(y: 2, anchor: .center)
            }
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.distanceText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Mesafe")
                        .font(.system(size: 9))
                        .foregroundStyle(secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(data.calories)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Kalori")
                        .font(.system(size: 9))
                        .foregroundStyle(secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(data.daysReached)/7")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Bu hafta")
                        .font(.system(size: 9))
                        .foregroundStyle(secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(bg)
    }
}

private struct CircularWidgetPreview: View {
    let data: SampleWidgetData
    private let accent = Color(red: 1, green: 0.42, blue: 0.21)
    private let secondary = Color(red: 0.61, green: 0.61, blue: 0.64)

    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.15, blue: 0.16)
            Circle()
                .stroke(secondary.opacity(0.3), lineWidth: 4)
                .padding(4)
            Circle()
                .trim(from: 0, to: CGFloat(data.progress))
                .stroke(
                    LinearGradient(colors: [accent, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(4)
            VStack(spacing: 0) {
                Text("\(data.steps)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                Image(systemName: "figure.walk")
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
            }
        }
        .clipShape(Circle())
    }
}

private struct RectangularWidgetPreview: View {
    let data: SampleWidgetData
    private let accent = Color(red: 1, green: 0.42, blue: 0.21)
    private let secondary = Color(red: 0.61, green: 0.61, blue: 0.64)

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 9))
                Text("Walkify")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(accent)
            Text("\(data.steps) / \(data.goal)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("\(data.distanceText) • \(data.calories) kcal")
                .font(.system(size: 8))
                .foregroundStyle(secondary)
            if data.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 7))
                    Text("\(data.streak) gün seri")
                        .font(.system(size: 7, weight: .medium))
                }
                .foregroundStyle(accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(red: 0.15, green: 0.15, blue: 0.16))
    }
}

private struct InlineWidgetPreview: View {
    let data: SampleWidgetData

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.system(size: 11))
            Text("\(data.steps.formatted()) adım • %\(data.progressPercent)")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.15, green: 0.15, blue: 0.16))
    }
}

// MARK: - Instruction Step

private struct InstructionStep: View {
    let number: Int
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.accentOrange)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.accentOrange.opacity(0.2)))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
        }
    }
}

#Preview {
    WidgetSheet(onDismiss: {})
}
