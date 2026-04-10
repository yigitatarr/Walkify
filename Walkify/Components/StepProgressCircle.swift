//
//  StepProgressCircle.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import SwiftUI

struct StepProgressCircle: View {
    @Environment(\.colorScheme) private var colorScheme
    let steps: Int
    let goal: Int
    let lineWidth: CGFloat

    init(steps: Int, goal: Int = 10000, lineWidth: CGFloat = 16) {
        self.steps = steps
        self.goal = goal
        self.lineWidth = lineWidth
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(AppTheme.cardBackgroundSecondary(for: colorScheme), lineWidth: lineWidth)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.accentGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)

            // Center content
            VStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.success)

                Text(NumberFormatter.stepsFormatter.string(from: NSNumber(value: steps)) ?? "0")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                Text("BUGÜN ADIM")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
    }
}

extension NumberFormatter {
    static var stepsFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        StepProgressCircle(steps: 8432, goal: 10000)
            .frame(width: 260, height: 260)
    }
}
