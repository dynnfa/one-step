import AppIntents
import OneStepCore
import SwiftUI
import WidgetKit

struct WidgetGoalRowView: View {
    let milestone: WidgetMilestoneSnapshot
    let compact: Bool
    let narrow: Bool

    var body: some View {
        let rowColor = Color(goalHex: milestone.colorHex)
        Button(intent: CompleteGoalIntent(goalID: milestone.id)) {
            HStack(spacing: narrow ? 4 : 6) {
                Image(systemName: milestone.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(rowColor)
                    .font(narrow ? .callout : .title3)

                VStack(alignment: .leading, spacing: narrow ? 1 : 2) {
                    Text(milestone.title)
                        .font(narrow ? .subheadline.bold() : .headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(milestone.parentFinalGoalTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(milestone.completedDays)/\(milestone.targetCompletionDays)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(milestone.isCompletedToday)
    }
}

private extension Color {
    init(goalHex hex: String) {
        guard let normalizedHex = FinalGoalColorTheme.normalizedHex(hex) else {
            self = Color.accentColor
            return
        }

        let rawHex = String(normalizedHex.dropFirst())
        let scanner = Scanner(string: rawHex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
