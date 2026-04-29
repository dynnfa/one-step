import SwiftUI

struct ContentView: View {
    @State private var store: GoalStore?
    @State private var startupError: String?
    @State private var isShowingCreateGoal = false

    var body: some View {
        Group {
            if let store {
                GoalListView(store: store, isShowingCreateGoal: $isShowingCreateGoal)
            } else {
                ContentUnavailableView(
                    "One Step could not open the shared store",
                    systemImage: "exclamationmark.triangle",
                    description: Text(startupError ?? "Unknown error")
                )
            }
        }
        .task {
            guard store == nil else { return }
            do {
                let liveStore = try GoalStore.live()
                liveStore.refresh()
                store = liveStore
            } catch {
                startupError = error.localizedDescription
            }
        }
        .sheet(isPresented: $isShowingCreateGoal) {
            if let store {
                GoalEditorView(mode: .create) { title, action, target in
                    store.createGoal(title: title, dailyAction: action, targetCompletionDays: target)
                    isShowingCreateGoal = false
                }
            }
        }
        .alert(
            "Add the One Step Widget",
            isPresented: Binding(
                get: { store?.didCreateFirstGoal == true },
                set: { _ in store?.didCreateFirstGoal = false }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your first goal is ready. Add the One Step Widget to complete it from the desktop.")
        }
        .frame(minWidth: 860, minHeight: 560)
    }
}

#Preview {
    ContentView()
}
