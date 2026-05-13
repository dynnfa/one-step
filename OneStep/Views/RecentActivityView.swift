import OneStepCore
import SwiftUI

struct RecentActivityView: View {
    let activity: [RecentActivityDay]
    let targetCompletionTimes: Int?
    var onRequiredDayCountChange: (Int) -> Void = { _ in }

    @State private var availableWidth: CGFloat?
    @State private var lastEmittedDayLimit: Int?

    private var visibleDayCount: Int {
        RecentActivityLayout.computeVisibleDayCount(
            availableWidth: availableWidth,
            activityCount: activity.count,
            targetCompletionTimes: targetCompletionTimes
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
            if availableWidth != width {
                availableWidth = width
            }
            let newLimit = RecentActivityLayout.computeRequiredDayLimit(
                availableWidth: width,
                targetCompletionTimes: targetCompletionTimes
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

    static func computeVisibleDayCount(
        availableWidth: CGFloat?,
        activityCount: Int,
        targetCompletionTimes: Int?,
        fallback: Int = fallbackDayCount
    ) -> Int {
        guard activityCount > 0 else { return 0 }
        let requestedDayCount = computeRequiredDayLimit(
            availableWidth: availableWidth,
            targetCompletionTimes: targetCompletionTimes,
            fallback: fallback
        )
        return min(activityCount, requestedDayCount)
    }

    static func computeRequiredDayLimit(
        availableWidth: CGFloat?,
        targetCompletionTimes: Int?,
        fallback: Int = fallbackDayCount
    ) -> Int {
        guard let availableWidth, availableWidth.isFinite else {
            return boundedByTarget(fallback, targetCompletionTimes: targetCompletionTimes)
        }

        let slotWidth = blockWidth + spacing
        let capacity = Int((availableWidth + spacing) / slotWidth)
        return boundedByTarget(max(1, capacity), targetCompletionTimes: targetCompletionTimes)
    }

    private static func boundedByTarget(_ dayCount: Int, targetCompletionTimes: Int?) -> Int {
        guard let targetCompletionTimes else { return dayCount }
        guard targetCompletionTimes > 0 else { return 0 }
        return min(dayCount, targetCompletionTimes)
    }
}

private struct RecentActivityWidthKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue()
    }
}
