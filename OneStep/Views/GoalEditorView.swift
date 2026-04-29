import SwiftUI

struct GoalEditorView: View {
    enum Mode {
        case create
        case edit(title: String, dailyAction: String, targetCompletionDays: Int)

        var title: String {
            switch self {
            case .create:
                return "Create Goal"
            case .edit:
                return "Edit Goal"
            }
        }
    }

    let mode: Mode
    let onSave: (String, String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var dailyAction: String
    @State private var targetCompletionDays: Int

    init(mode: Mode, onSave: @escaping (String, String, Int) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _dailyAction = State(initialValue: "")
            _targetCompletionDays = State(initialValue: 200)
        case let .edit(title, dailyAction, targetCompletionDays):
            _title = State(initialValue: title)
            _dailyAction = State(initialValue: dailyAction)
            _targetCompletionDays = State(initialValue: targetCompletionDays)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("Vocabulary", text: $title).textFieldStyle(.roundedBorder)
            TextField("Study 30 minutes", text: $dailyAction).textFieldStyle(.roundedBorder)
            Stepper(value: $targetCompletionDays, in: 1...10_000) {
                Text("Target: \(targetCompletionDays) completed days")
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { onSave(title, dailyAction, targetCompletionDays) }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            dailyAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
