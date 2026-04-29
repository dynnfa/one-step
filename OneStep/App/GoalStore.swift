import Foundation
import Observation
import OneStepCore
import WidgetKit

@MainActor
@Observable
final class GoalStore {
    private let repository: GoalRepository

    var goals: [GoalListSnapshot] = []
    var errorMessage: String?
    var didCreateFirstGoal = false

    init(repository: GoalRepository) {
        self.repository = repository
    }

    static func live() throws -> GoalStore {
        GoalStore(repository: try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier))
    }

    func refresh(day: LocalDay = .today) {
        do {
            goals = try repository.goalsForList(day: day)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            OneStepLog.repository.error("App refresh failed: \(error.localizedDescription)")
        }
    }

    func createGoal(title: String, dailyAction: String, targetCompletionDays: Int) {
        do {
            let wasEmpty = goals.isEmpty
            _ = try repository.createGoal(CreateGoalInput(
                title: title,
                dailyAction: dailyAction,
                targetCompletionDays: targetCompletionDays,
                startDay: .today
            ))
            didCreateFirstGoal = wasEmpty
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateGoal(goalID: UUID, title: String, dailyAction: String, targetCompletionDays: Int) {
        do {
            try repository.updateGoal(
                goalID: goalID,
                input: UpdateGoalInput(title: title, dailyAction: dailyAction, targetCompletionDays: targetCompletionDays)
            )
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeToday(goalID: UUID) {
        do {
            try repository.completeToday(goalID: goalID, day: .today)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uncompleteToday(goalID: UUID) {
        do {
            try repository.uncompleteToday(goalID: goalID, day: .today)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveGoal(goalID: UUID) {
        do {
            try repository.archiveGoal(goalID: goalID, archivedAt: Date())
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        let activeGoals = goals.filter { $0.archivedAt == nil }
        guard sourceIndex < activeGoals.count else { return }

        do {
            try repository.moveActiveGoal(goalID: activeGoals[sourceIndex].id, toIndex: destination)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshAndReloadWidget() {
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
    }
}
