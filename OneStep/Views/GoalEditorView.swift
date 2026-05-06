import SwiftUI

struct FinalGoalEditorView: View {
    private static let dayCountRange = 1...10_000

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
    @State private var isTargetCalendarDaysValid = true

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
            && (!hasCalendarLimit || isTargetCalendarDaysValid)
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
                DayCountStepperInput(
                    title: "Target",
                    unit: "calendar days",
                    value: $targetCalendarDays,
                    range: Self.dayCountRange,
                    isValid: $isTargetCalendarDaysValid
                )
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
    private static let dayCountRange = 1...10_000

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
    @State private var isTargetCompletionDaysValid = true

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
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isTargetCompletionDaysValid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("Finish vocabulary", text: $title).textFieldStyle(.roundedBorder)
            DayCountStepperInput(
                title: "Target",
                unit: "completed days",
                value: $targetCompletionDays,
                range: Self.dayCountRange,
                isValid: $isTargetCompletionDaysValid
            )
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

struct DayCountInputValidator {
    static func parse(_ text: String, range: ClosedRange<Int>) -> Int? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmedText), range.contains(value) else {
            return nil
        }
        return value
    }
}

private struct DayCountStepperInput: View {
    let title: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    @Binding var isValid: Bool

    @State private var text: String

    init(
        title: String,
        unit: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        isValid: Binding<Bool>
    ) {
        self.title = title
        self.unit = unit
        _value = value
        self.range = range
        _isValid = isValid
        _text = State(initialValue: String(value.wrappedValue))
    }

    private var stepperValue: Binding<Int> {
        Binding(
            get: { value },
            set: { newValue in
                value = newValue
                text = String(newValue)
                isValid = true
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(title)
                Spacer()
                TextField(title, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 86)
                    .onChange(of: text) { _, newValue in
                        updateValue(from: newValue)
                    }
                Text(unit)
                    .foregroundStyle(.secondary)
                Stepper("", value: stepperValue, in: range)
                    .labelsHidden()
                    .frame(width: 54)
            }
            if !isValid {
                Text("Enter a number from \(range.lowerBound) to \(range.upperBound).")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func updateValue(from text: String) {
        guard let parsedValue = DayCountInputValidator.parse(text, range: range) else {
            isValid = false
            return
        }
        value = parsedValue
        isValid = true
    }
}
