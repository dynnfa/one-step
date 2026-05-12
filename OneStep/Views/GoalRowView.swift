import OneStepCore
import SwiftUI

struct FinalGoalRowView: View {
    let goal: FinalGoalListSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.headline)
                    .foregroundStyle(Color(goalHex: goal.colorHex))
                if goal.totalMilestoneCount > 0 {
                    Text("\(goal.completedMilestoneCount)/\(goal.totalMilestoneCount) milestones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if goal.archivedAt != nil {
                Image(systemName: "archivebox")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MilestoneGoalRowView: View {
    let milestone: MilestoneGoalSnapshot
    let isReadOnly: Bool
    let onCheckIn: () -> Void
    let onUndo: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetActive: (Bool) -> Void
    let onRecentActivityDayLimitChange: (Int) -> Void

    @State private var isConfirmingDelete = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: milestone.isCompletedToday ? onUndo : onCheckIn) {
                Image(systemName: milestone.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(isReadOnly || !milestone.isActive || milestone.completedAt != nil)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(milestone.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(0)
                    if milestone.isActive {
                        Text("active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15))
                            .clipShape(Capsule())
                            .fixedSize()
                    } else if milestone.completedAt == nil {
                        Text("inactive")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                            .fixedSize()
                    }
                    if milestone.completedAt != nil {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .fixedSize()
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                RecentActivityView(
                    activity: milestone.recentActivity,
                    targetCompletionDays: milestone.targetCompletionDays,
                    onRequiredDayCountChange: onRecentActivityDayLimitChange
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                if !isReadOnly && milestone.completedAt == nil {
                    CapsuleToggleButton(
                        title: milestone.isActive ? "Deactivate" : "Activate",
                        strokeColor: milestone.isActive ? Color.secondary.opacity(0.4) : .blue.opacity(0.5),
                        textColor: milestone.isActive ? .secondary : .blue
                    ) { onSetActive(!milestone.isActive) }
                }

                Text("\(milestone.completedDays)/\(milestone.targetCompletionDays)")
                    .font(.headline.monospacedDigit())
            }

            if !isReadOnly {
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive) {
                        isConfirmingDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.button)
                .frame(width: 32)
            }
        }
        .padding(.vertical, 10)
        .confirmationDialog(
            "Delete Milestone?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Milestone", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the milestone and its completion history.")
        }
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

private struct CapsuleToggleButton: View {
    let title: String
    let strokeColor: Color
    let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(textColor)
    }
}
