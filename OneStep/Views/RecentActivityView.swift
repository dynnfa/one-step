import OneStepCore
import SwiftUI

struct RecentActivityView: View {
    let activity: [RecentActivityDay]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(activity.suffix(30)) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(day.isCompleted ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: 8, height: 18)
                    .accessibilityLabel("\(day.day.rawValue) \(day.isCompleted ? "completed" : "missed")")
            }
        }
    }
}
