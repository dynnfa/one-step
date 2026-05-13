import AppKit
import OneStepCore
import SwiftUI

struct FinalGoalEditorView: View {
    private static let dayCountRange = 1...10_000

    enum Mode {
        case create
        case edit(
            title: String,
            goalDescription: String?,
            targetCalendarDays: Int?,
            colorThemeID: String,
            customColorHex: String?
        )

        var title: String {
            switch self {
            case .create: return "Create Goal"
            case .edit: return "Edit Goal"
            }
        }
    }

    let mode: Mode
    let onSave: (String, String?, Int?, String, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var goalDescription: String
    @State private var hasCalendarLimit: Bool
    @State private var targetCalendarDays: Int
    @State private var isTargetCalendarDaysValid = true
    @State private var colorThemeID: String
    @State private var customColorHex: String?
    @State private var customColor: Color

    init(mode: Mode, onSave: @escaping (String, String?, Int?, String, String?) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _goalDescription = State(initialValue: "")
            _hasCalendarLimit = State(initialValue: false)
            _targetCalendarDays = State(initialValue: 180)
            _colorThemeID = State(initialValue: FinalGoalColorTheme.defaultTheme.id)
            _customColorHex = State(initialValue: nil)
            _customColor = State(initialValue: Color(goalHex: FinalGoalColorTheme.defaultTheme.hex))
        case let .edit(title, description, target, colorThemeID, customColorHex):
            _title = State(initialValue: title)
            _goalDescription = State(initialValue: description ?? "")
            _hasCalendarLimit = State(initialValue: target != nil)
            _targetCalendarDays = State(initialValue: target ?? 180)
            let colorSelection = FinalGoalColorTheme.sanitizedSelection(
                themeID: colorThemeID,
                customColorHex: customColorHex
            )
            _colorThemeID = State(initialValue: colorSelection.themeID)
            _customColorHex = State(initialValue: colorSelection.customColorHex)
            _customColor = State(initialValue: Color(goalHex: colorSelection.colorHex))
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!hasCalendarLimit || isTargetCalendarDaysValid)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("What do you want to achieve?", text: $title).textFieldStyle(.roundedBorder)
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
            GoalColorPicker(
                selectedThemeID: $colorThemeID,
                customColorHex: $customColorHex,
                customColor: $customColor
            )
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let trimmedDesc = goalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(
                        title,
                        trimmedDesc.isEmpty ? nil : trimmedDesc,
                        hasCalendarLimit ? targetCalendarDays : nil,
                        colorThemeID,
                        customColorHex
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

private struct GoalColorPicker: View {
    @Binding var selectedThemeID: String
    @Binding var customColorHex: String?
    @Binding var customColor: Color

    private var customColorBinding: Binding<Color> {
        Binding(
            get: { customColor },
            set: { newColor in
                customColor = newColor
                selectedThemeID = FinalGoalColorTheme.customID
                customColorHex = newColor.goalHex
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.headline)
            HStack(spacing: 10) {
                ForEach(FinalGoalColorTheme.presets) { theme in
                    Button {
                        selectedThemeID = theme.id
                        customColorHex = nil
                    } label: {
                        colorSwatch(
                            color: Color(goalHex: theme.hex),
                            isSelected: selectedThemeID == theme.id
                        )
                    }
                    .buttonStyle(.plain)
                    .help(theme.displayName)
                }

                Button {
                    selectedThemeID = FinalGoalColorTheme.customID
                    customColorHex = customColor.goalHex
                } label: {
                    colorSwatch(
                        color: customColor,
                        isSelected: selectedThemeID == FinalGoalColorTheme.customID
                    )
                }
                .buttonStyle(.plain)
                .help("Custom")

                ColorPicker("", selection: customColorBinding, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 28)
                .help("Choose Custom Color")
            }
        }
    }

    private func colorSwatch(color: Color, isSelected: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.35), lineWidth: isSelected ? 3 : 1)
            }
            .padding(3)
    }
}

struct MilestoneGoalEditorView: View {
    private static let timesCountRange = 1...10_000

    enum Mode {
        case create
        case edit(title: String, targetCompletionTimes: Int?)

        var title: String {
            switch self {
            case .create: return "Add Milestone"
            case .edit: return "Edit Milestone"
            }
        }
    }

    let mode: Mode
    let onSave: (String, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var hasTargetCompletionTimes: Bool
    @State private var targetCompletionTimes: Int
    @State private var isTargetCompletionTimesValid = true

    init(mode: Mode, onSave: @escaping (String, Int?) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .create:
            _title = State(initialValue: "")
            _hasTargetCompletionTimes = State(initialValue: true)
            _targetCompletionTimes = State(initialValue: 30)
        case let .edit(title, targetCompletionTimes):
            _title = State(initialValue: title)
            _hasTargetCompletionTimes = State(initialValue: targetCompletionTimes != nil)
            _targetCompletionTimes = State(initialValue: targetCompletionTimes ?? 30)
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!hasTargetCompletionTimes || isTargetCompletionTimesValid)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title).font(.title2.bold())
            TextField("Milestone title", text: $title).textFieldStyle(.roundedBorder)
            Toggle("Set target times", isOn: $hasTargetCompletionTimes)
            if hasTargetCompletionTimes {
                DayCountStepperInput(
                    title: "Target",
                    unit: "times",
                    value: $targetCompletionTimes,
                    range: Self.timesCountRange,
                    isValid: $isTargetCompletionTimesValid
                )
            } else {
                Label("Unlimited", systemImage: "infinity")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    onSave(title, hasTargetCompletionTimes ? targetCompletionTimes : nil)
                }
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
