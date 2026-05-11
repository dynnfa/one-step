import Foundation
import Observation
import OneStepCore
import WidgetKit

@MainActor
@Observable
final class MilestoneGoalStore {
    private let repository: MilestoneGoalRepository
    private var recentActivityDayLimit = 30
    private var pendingRecentActivityRefreshTask: Task<Void, Never>?

    @ObservationIgnored var onMilestonesChanged: (() -> Void)?

    var milestones: [MilestoneGoalSnapshot] = []
    var errorMessage: String?

    init(repository: MilestoneGoalRepository) {
        self.repository = repository
    }

    static func live() throws -> MilestoneGoalStore {
        MilestoneGoalStore(repository: try MilestoneGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier))
    }

    func refresh(finalGoalID: UUID, day: LocalDay = .today) {
        do {
            milestones = try repository.milestonesForFinalGoal(
                finalGoalID: finalGoalID,
                day: day,
                recentActivityDayLimit: recentActivityDayLimit
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            OneStepLog.repository.error("Milestone refresh failed: \(error.localizedDescription)")
        }
    }

    func ensureRecentActivityDayLimit(_ dayLimit: Int, finalGoalID: UUID, day: LocalDay = .today) {
        guard dayLimit > recentActivityDayLimit else { return }
        recentActivityDayLimit = dayLimit
        pendingRecentActivityRefreshTask?.cancel()
        pendingRecentActivityRefreshTask = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            refresh(finalGoalID: finalGoalID, day: day)
            pendingRecentActivityRefreshTask = nil
        }
    }

    func createMilestone(title: String, targetCompletionDays: Int, finalGoalID: UUID) {
        do {
            _ = try repository.createMilestoneGoal(CreateMilestoneGoalInput(
                title: title,
                targetCompletionDays: targetCompletionDays,
                finalGoalID: finalGoalID
            ))
            refreshAndReloadWidget(finalGoalID: finalGoalID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateMilestone(milestoneGoalID: UUID, finalGoalID: UUID, title: String, targetCompletionDays: Int) {
        do {
            try repository.updateMilestoneGoal(
                milestoneGoalID: milestoneGoalID,
                input: UpdateMilestoneGoalInput(title: title, targetCompletionDays: targetCompletionDays)
            )
            refreshAndReloadWidget(finalGoalID: finalGoalID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeToday(milestoneGoalID: UUID, finalGoalID: UUID) {
        do {
            try repository.completeToday(milestoneGoalID: milestoneGoalID, day: .today)
            refreshAndReloadWidget(finalGoalID: finalGoalID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uncompleteToday(milestoneGoalID: UUID, finalGoalID: UUID) {
        do {
            try repository.uncompleteToday(milestoneGoalID: milestoneGoalID, day: .today)
            refreshAndReloadWidget(finalGoalID: finalGoalID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMilestone(milestoneGoalID: UUID, finalGoalID: UUID) {
        do {
            try repository.deleteMilestoneGoal(milestoneGoalID: milestoneGoalID)
            refreshAndReloadWidget(finalGoalID: finalGoalID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setMilestoneActive(milestoneGoalID: UUID, finalGoalID: UUID, isActive: Bool) {
        do {
            try repository.setMilestoneActive(milestoneGoalID: milestoneGoalID, isActive: isActive)
            refreshAndReloadWidget(finalGoalID: finalGoalID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshAndReloadWidget(finalGoalID: UUID) {
        pendingRecentActivityRefreshTask?.cancel()
        pendingRecentActivityRefreshTask = nil
        refresh(finalGoalID: finalGoalID)
        WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
        onMilestonesChanged?()
    }
}
