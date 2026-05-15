import OneStepCore
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @State private var finalGoalStore: FinalGoalStore?
    @State private var milestoneStore: MilestoneGoalStore?
    @State private var dataPortStore: DataPortStore?
    @State private var goalDataChangeObservation: GoalDataChangeObservation?
    @State private var externalRefreshScheduler = GoalDataExternalRefreshScheduler()
    @State private var startupError: String?
    @State private var isShowingCreateGoal = false
    @State private var isShowingImporter = false
    @State private var isShowingExporter = false
    @State private var isConfirmingImport = false
    @State private var exportFile = OneStepBackupFile(data: Data())

    var body: some View {
        Group {
            if let finalGoalStore, let milestoneStore, let dataPortStore {
                GoalListView(
                    finalGoalStore: finalGoalStore,
                    milestoneStore: milestoneStore,
                    dataPortStore: dataPortStore,
                    isShowingCreateGoal: $isShowingCreateGoal,
                    onImportData: { isConfirmingImport = true },
                    onExportData: {
                        if let file = dataPortStore.makeExportFile() {
                            exportFile = file
                            isShowingExporter = true
                        }
                    }
                )
            } else {
                ContentUnavailableView(
                    "One Step could not open the shared store",
                    systemImage: "exclamationmark.triangle",
                    description: Text(startupError ?? "Unknown error")
                )
            }
        }
        .task {
            guard finalGoalStore == nil else { return }
            do {
                let container = try OneStepModelContainerFactory.sharedContainer(
                    appGroupIdentifier: AppIdentifiers.appGroupIdentifier
                )
                let modelContext = ModelContext(container)

                let milestoneRepository = MilestoneGoalRepository(modelContext: modelContext)
                try backfillLegacyActiveMilestonesIfNeeded(repository: milestoneRepository)

                let fgStore = FinalGoalStore(repository: FinalGoalRepository(modelContext: modelContext))
                fgStore.refresh()
                finalGoalStore = fgStore

                let msStore = MilestoneGoalStore(repository: milestoneRepository)
                GoalDataRefreshCoordinator.connect(finalGoalStore: fgStore, milestoneStore: msStore)
                goalDataChangeObservation = GoalDataChangeNotifier.observe {
                    GoalDataRefreshCoordinator.refreshAfterGoalDataChange(
                        finalGoalStore: fgStore,
                        milestoneStore: msStore
                    )
                }
                milestoneStore = msStore

                dataPortStore = DataPortStore(repository: OneStepBackupRepository(modelContext: modelContext))
            } catch {
                startupError = error.localizedDescription
            }
        }
        .onChange(of: controlActiveState) { _, newState in
            guard let finalGoalStore,
                  let milestoneStore else { return }
            externalRefreshScheduler.controlActiveStateDidChange(
                newState,
                finalGoalStore: finalGoalStore,
                milestoneStore: milestoneStore
            )
        }
        .sheet(isPresented: $isShowingCreateGoal) {
            if let finalGoalStore {
                FinalGoalEditorView(mode: .create) { title, description, target, colorThemeID, customColorHex in
                    finalGoalStore.createFinalGoal(
                        title: title,
                        goalDescription: description,
                        targetCalendarDays: target,
                        colorThemeID: colorThemeID,
                        customColorHex: customColorHex
                    )
                    isShowingCreateGoal = false
                }
            }
        }
        .alert(
            "Replace All Data?",
            isPresented: $isConfirmingImport
        ) {
            Button("Choose Backup") {
                isShowingImporter = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Importing a backup replaces every goal, milestone, and completion currently stored on this Mac.")
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.oneStepBackup, .json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do {
                    let data = try Data(contentsOf: url)
                    dataPortStore?.importData(data)
                    guard let finalGoalStore, let milestoneStore else { return }
                    GoalDataRefreshCoordinator.refreshAfterGoalDataChange(
                        finalGoalStore: finalGoalStore,
                        milestoneStore: milestoneStore
                    )
                } catch {
                    dataPortStore?.errorMessage = error.localizedDescription
                }
            case .failure(let error):
                dataPortStore?.errorMessage = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isShowingExporter,
            document: exportFile,
            contentType: .oneStepBackup,
            defaultFilename: DataPortStore.defaultExportFilename()
        ) { result in
            if case .failure(let error) = result {
                dataPortStore?.errorMessage = error.localizedDescription
            }
        }
        .alert(
            "Add the One Step Widget",
            isPresented: Binding(
                get: { finalGoalStore?.didCreateFirstGoal == true },
                set: { _ in finalGoalStore?.didCreateFirstGoal = false }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your first goal is ready. Add the One Step Widget to check in from the desktop.")
        }
        .frame(minWidth: 860, minHeight: 560)
    }

    private func backfillLegacyActiveMilestonesIfNeeded(repository: MilestoneGoalRepository) throws {
        let defaults = UserDefaults(suiteName: AppIdentifiers.appGroupIdentifier) ?? .standard
        let key = "didBackfillLegacyActiveMilestonesForExplicitState"
        guard !defaults.bool(forKey: key) else { return }
        try repository.backfillLegacyActiveMilestonesIfNeeded()
        defaults.set(true, forKey: key)
    }
}

#Preview {
    ContentView()
}
