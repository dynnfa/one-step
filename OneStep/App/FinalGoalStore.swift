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

    func createFinalGoal(
        title: String,
        goalDescription: String?,
        targetCalendarDays: Int?,
        colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
        customColorHex: String? = nil
    ) {
        do {
            let wasEmpty = finalGoals.filter { $0.archivedAt == nil }.isEmpty
            _ = try repository.createFinalGoal(CreateFinalGoalInput(
                title: title,
                goalDescription: goalDescription,
                targetCalendarDays: targetCalendarDays,
                colorThemeID: colorThemeID,
                customColorHex: customColorHex,
                startDay: .today
            ))
            didCreateFirstGoal = wasEmpty
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFinalGoal(
        finalGoalID: UUID,
        title: String,
        goalDescription: String?,
        targetCalendarDays: Int?,
        colorThemeID: String = FinalGoalColorTheme.defaultTheme.id,
        customColorHex: String? = nil
    ) {
        do {
            try repository.updateFinalGoal(
                finalGoalID: finalGoalID,
                input: UpdateFinalGoalInput(
                    title: title,
                    goalDescription: goalDescription,
                    targetCalendarDays: targetCalendarDays,
                    colorThemeID: colorThemeID,
                    customColorHex: customColorHex
                )
            )
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFinalGoalArchive(finalGoalID: UUID) {
        do {
            let shouldArchive = finalGoals.first { $0.id == finalGoalID }?.archivedAt == nil
            try repository.setFinalGoalArchived(finalGoalID: finalGoalID, isArchived: shouldArchive)
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFinalGoal(finalGoalID: UUID) {
        do {
            try repository.deleteFinalGoal(finalGoalID: finalGoalID)
            if selectedFinalGoalID == finalGoalID {
                selectedFinalGoalID = nil
            }
            refreshAndReloadWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        let activeGoals = finalGoals.filter { $0.archivedAt == nil }
        guard sourceIndex < activeGoals.count else { return }

        do {
            try repository.moveActiveFinalGoal(finalGoalID: activeGoals[sourceIndex].id, toIndex: destination)
            reorderLocally(activeGoals: activeGoals, source: sourceIndex, destination: destination)
            WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ id: UUID?) {
        selectedFinalGoalID = id
    }

    private func reorderLocally(activeGoals: [FinalGoalListSnapshot], source: Int, destination: Int) {
        var reordered = activeGoals
        guard reordered.indices.contains(source) else { return }
        let moved = reordered.remove(at: source)
        let target = min(max(destination, 0), reordered.count)
        reordered.insert(moved, at: target)

        var result: [FinalGoalListSnapshot] = []
        var idx = 0
        for goal in finalGoals {
            if goal.archivedAt == nil {
                result.append(reordered[idx])
                idx += 1
            } else {
                result.append(goal)
            }
        }
        finalGoals = result
    }

    private func refreshAndReloadWidget() {
        refresh()
        WidgetCenter.shared.reloadTimelines(ofKind: "OneStepWidget")
    }
}

/// Computes the target index for `FinalGoalStore.move(from:to:)` when reordering with above/below semantics.
/// The `to` index follows Swift's remove-then-insert convention (index in the array after source removal).
func computeGoalReorderIndex(source: Int, dest: Int, insertAbove: Bool) -> Int {
    var insertionIndex = insertAbove ? dest : dest + 1
    if source < insertionIndex {
        insertionIndex -= 1
    }
    return max(insertionIndex, 0)
}
