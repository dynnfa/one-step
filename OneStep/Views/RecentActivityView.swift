import OneStepCore
import SwiftUI

struct RecentActivityView: View {
    let activity: [RecentActivityDay]
    let targetCompletionDays: Int
    var onRequiredDayCountChange: (Int) -> Void = { _ in }

    @State private var availableWidth: CGFloat?
    @State private var lastEmittedDayLimit: Int?

    private var visibleDayCount: Int {
        computeVisibleRecentActivityDayCount(
            availableWidth: availableWidth,
            activityCount: activity.count,
            targetCompletionDays: targetCompletionDays
        )
    }

    var body: some View {
        HStack(spacing: RecentActivityLayout.spacing) {
            ForEach(activity.suffix(visibleDayCount)) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(day.isCompleted ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: RecentActivityLayout.blockWidth, height: RecentActivityLayout.blockHeight)
                    .accessibilityLabel("\(day.day.rawValue) \(day.isCompleted ? "completed" : "missed")")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: RecentActivityWidthKey.self,
                    value: geo.size.width.isFinite ? geo.size.width : nil
                )
            }
        )
        .onPreferenceChange(RecentActivityWidthKey.self) { width in
            availableWidth = width
            let newLimit = computeRequiredRecentActivityDayLimit(
                availableWidth: width,
                targetCompletionDays: targetCompletionDays
            )
            guard newLimit != lastEmittedDayLimit else { return }
            lastEmittedDayLimit = newLimit
            onRequiredDayCountChange(newLimit)
        }
    }
}

enum RecentActivityLayout {
    static let blockWidth: CGFloat = 8
    static let blockHeight: CGFloat = 18
    static let spacing: CGFloat = 3
    static let fallbackDayCount = 30
}

func computeVisibleRecentActivityDayCount(
    availableWidth: CGFloat?,
    activityCount: Int,
    targetCompletionDays: Int,
    fallback: Int = RecentActivityLayout.fallbackDayCount
) -> Int {
    guard activityCount > 0, targetCompletionDays > 0 else { return 0 }
    let requestedDayCount = computeRequiredRecentActivityDayLimit(
        availableWidth: availableWidth,
        targetCompletionDays: targetCompletionDays,
        fallback: fallback
    )
    return min(activityCount, requestedDayCount)
}

func computeRequiredRecentActivityDayLimit(
    availableWidth: CGFloat?,
    targetCompletionDays: Int,
    fallback: Int = RecentActivityLayout.fallbackDayCount
) -> Int {
    guard targetCompletionDays > 0 else { return 0 }
    guard let availableWidth, availableWidth.isFinite else {
        return min(fallback, targetCompletionDays)
    }

    let slotWidth = RecentActivityLayout.blockWidth + RecentActivityLayout.spacing
    let capacity = Int((availableWidth + RecentActivityLayout.spacing) / slotWidth)
    return min(max(1, capacity), targetCompletionDays)
}

private struct RecentActivityWidthKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue()
    }
}
