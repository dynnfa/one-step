import Foundation
import Observation
import OneStepCore
import WidgetKit

@MainActor
@Observable
final class FinalGoalStore {
    private let repository: FinalGoalRepository

    var finalGoals: [FinalGoalListSnapshot] = []
    var selectedFinalGoalID: UUID?
    var errorMessage: String?
    var didCreateFirstGoal = false

    init(repository: FinalGoalRepository) {
        self.repository = repository
    }

    static func live() throws -> FinalGoalStore {
        FinalGoalStore(repository: try FinalGoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier))
    }

    func refresh() {
        do {
            finalGoals = try repository.finalGoalsForList()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            OneStepLog.repository.error("FinalGoal refresh failed: \(error.localizedDescription)")
        }
    }

    func createFinalGoal(title: String, goalDescription: String?, targetCalendarDays: Int?) {
        do {
            let wasEmpty = finalGoals.filter { $0.archivedAt == nil && $0.completedAt == nil }.isEmpty
            _ = try repository.createFinalGoal(CreateFinalGoalInput(
                title: title,
                goalDescription: goalDescription,
                targetCalendarDays: targetCalendarDays,
                startDay: .today
            ))
            didCreateFirstGoal = wasEmpty
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFinalGoal(finalGoalID: UUID, title: String, goalDescription: String?, targetCalendarDays: Int?) {
        do {
            try repository.updateFinalGoal(
                finalGoalID: finalGoalID,
                input: UpdateFinalGoalInput(title: title, goalDescription: goalDescription, targetCalendarDays: targetCalendarDays)
            )
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeFinalGoal(finalGoalID: UUID) {
        do {
            try repository.completeFinalGoal(finalGoalID: finalGoalID, completedAt: Date())
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveFinalGoal(finalGoalID: UUID) {
        do {
            try repository.archiveFinalGoal(finalGoalID: finalGoalID, archivedAt: Date())
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        let activeGoals = finalGoals.filter { $0.archivedAt == nil && $0.completedAt == nil }
        guard sourceIndex < activeGoals.count else { return }

        do {
            try repository.moveActiveFinalGoal(finalGoalID: activeGoals[sourceIndex].id, toIndex: destination)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ id: UUID?) {
        selectedFinalGoalID = id
    }

    private func refreshAndReloadWidget() {
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
    }
}
