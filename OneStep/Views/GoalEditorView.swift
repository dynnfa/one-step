import SwiftUI

struct FinalGoalEditorView: View {
    enum Mode {
        case create
        case edit(title: String, goalDescription: String?, targetCalendarDays: Int?)

        var title: String {
            switch self {
            case .create: return "Create Goal"
            case .edit: return "Edit Goal"
            }
        }
    }

    let mode: Mode
    let onSave: (String, String?, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var goalDescription: String
    @State private var hasCalendarLimit: Bool
    @State private var targetCalendarDays: Int

    init(mode: Mode, onSave: @escaping (String, String?, Int?) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _goalDescription = State(initialValue: "")
            _hasCalendarLimit = State(initialValue: false)
            _targetCalendarDays = State(initialValue: 180)
        case let .edit(title, description, target):
            _title = State(initialValue: title)
            _goalDescription = State(initialValue: description ?? "")
            _hasCalendarLimit = State(initialValue: target != nil)
            _targetCalendarDays = State(initialValue: target ?? 180)
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("Pass IELTS", text: $title).textFieldStyle(.roundedBorder)
            TextField("Description (optional)", text: $goalDescription, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            Toggle("Set calendar-day limit", isOn: $hasCalendarLimit)
            if hasCalendarLimit {
                Stepper(value: $targetCalendarDays, in: 1...10_000) {
                    Text("Target: \(targetCalendarDays) calendar days")
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let trimmedDesc = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(
                        title,
                        trimmedDesc.isEmpty ? nil : trimmedDesc,
                        hasCalendarLimit ? targetCalendarDays : nil
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

struct MilestoneGoalEditorView: View {
    enum Mode {
        case create
        case edit(title: String, targetCompletionDays: Int)

        var title: String {
            switch self {
            case .create: return "Add Milestone"
            case .edit: return "Edit Milestone"
            }
        }
    }

    let mode: Mode
    let onSave: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var targetCompletionDays: Int

    init(mode: Mode, onSave: @escaping (String, Int) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _targetCompletionDays = State(initialValue: 30)
        case let .edit(title, targetCompletionDays):
            _title = State(initialValue: title)
            _targetCompletionDays = State(initialValue: targetCompletionDays)
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetCompletionDays > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("Finish vocabulary", text: $title).textFieldStyle(.roundedBorder)
            Stepper(value: $targetCompletionDays, in: 1...10_000) {
                Text("Target: \(targetCompletionDays) completed days")
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { onSave(title, targetCompletionDays) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
