import SwiftUI

struct ContentView: View {
    @State private var finalGoalStore: FinalGoalStore?
    @State private var milestoneStore: MilestoneGoalStore?
    @State private var startupError: String?
    @State private var isShowingCreateGoal = false

    var body: some View {
        Group {
            if let finalGoalStore, let milestoneStore {
                GoalListView(
                    finalGoalStore: finalGoalStore,
                    milestoneStore: milestoneStore,
                    isShowingCreateGoal: $isShowingCreateGoal
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
