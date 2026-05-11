import SwiftUI

struct ContentView: View {
    @State private var finalGoalStore: FinalGoalStore?
    @State private var milestoneStore: MilestoneGoalStore?
    @State private var dataPortStore: DataPortStore?
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
                let fgStore = try FinalGoalStore.live()
                fgStore.refresh()
                finalGoalStore = fgStore

                let msStore = try MilestoneGoalStore.live()
                milestoneStore = msStore

                dataPortStore = try DataPortStore.live()
            } catch {
                startupError = error.localizedDescription
            }
        }
        .sheet(isPresented: $isShowingCreateGoal) {
            if let finalGoalStore {
                FinalGoalEditorView(mode: .create) { title, description, target in
                    finalGoalStore.createFinalGoal(
                        title: title, goalDescription: description, targetCalendarDays: target
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
                    finalGoalStore?.refresh()
                    if let selectedID = finalGoalStore?.selectedFinalGoalID {
                        if finalGoalStore?.finalGoals.contains(where: { $0.id == selectedID }) == true {
                            milestoneStore?.refresh(finalGoalID: selectedID)
                        } else {
                            finalGoalStore?.select(nil)
                            milestoneStore?.milestones = []
                        }
                    }
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
}

#Preview {
    ContentView()
}
