import OneStepCore
import SwiftUI

struct ContentView: View {
    @State private var message = "Create a spike goal, then add the Widget."

    var body: some View {
        VStack(spacing: 16) {
            Text("One Step")
                .font(.largeTitle.bold())

            Text(message)
                .foregroundStyle(.secondary)

            Button("Create Spike Goal") {
                createSpikeGoal()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 640, minHeight: 420)
    }

    @MainActor
    private func createSpikeGoal() {
        do {
            let repository = try GoalRepository.shared(appGroupIdentifier: AppConstants.appGroupIdentifier)
            let id = try repository.createGoal(CreateGoalInput(
                title: "Vocabulary",
                dailyAction: "Study 30 minutes",
                targetCompletionDays: 200,
                startDay: .today
            ))
            message = "Created spike goal \(id.uuidString.prefix(8)). Add or refresh the Widget."
        } catch {
            OneStepLog.store.error("Spike goal creation failed: \(error.localizedDescription)")
            message = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
