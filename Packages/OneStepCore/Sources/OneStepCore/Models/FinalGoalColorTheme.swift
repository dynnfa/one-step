import Foundation

public struct FinalGoalColorTheme: Equatable, Identifiable, Sendable {
    public static let customID = "custom"

    public static let black = FinalGoalColorTheme(id: "black", displayName: "Black", hex: "#000000")
    public static let blue = FinalGoalColorTheme(id: "blue", displayName: "Blue", hex: "#007AFF")
    public static let green = FinalGoalColorTheme(id: "green", displayName: "Green", hex: "#34C759")
    public static let orange = FinalGoalColorTheme(id: "orange", displayName: "Orange", hex: "#FF9500")
    public static let pink = FinalGoalColorTheme(id: "pink", displayName: "Pink", hex: "#FF2D55")
    public static let purple = FinalGoalColorTheme(id: "purple", displayName: "Purple", hex: "#AF52DE")
    public static let teal = FinalGoalColorTheme(id: "teal", displayName: "Teal", hex: "#30B0C7")

    public static let presets = [black, blue, green, orange, pink, purple, teal]
    public static let defaultTheme = black

    public let id: String
    public let displayName: String
    public let hex: String

    public static func theme(id: String) -> FinalGoalColorTheme {
        presets.first { $0.id == id } ?? defaultTheme
    }

    public static func normalizedHex(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawHex = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        let expanded: String

        switch rawHex.count {
        case 3:
            expanded = rawHex.map { "\($0)\($0)" }.joined()
        case 6:
            expanded = rawHex
        default:
            return nil
        }

        guard expanded.allSatisfy(\.isHexDigit) else { return nil }
        return "#\(expanded.uppercased())"
    }

    public static func resolvedHex(themeID: String, customColorHex: String?) -> String {
        if themeID == customID {
            return normalizedHex(customColorHex) ?? defaultTheme.hex
        }
        return theme(id: themeID).hex
    }

    public static func sanitizedSelection(
        themeID: String?,
        customColorHex: String?
    ) -> (themeID: String, customColorHex: String?, colorHex: String) {
        guard let themeID else {
            return (defaultTheme.id, nil, defaultTheme.hex)
        }

        if themeID == customID {
            guard let normalizedCustomHex = normalizedHex(customColorHex) else {
                return (defaultTheme.id, nil, defaultTheme.hex)
            }
            return (customID, normalizedCustomHex, normalizedCustomHex)
        }

        let preset = theme(id: themeID)
        return (preset.id, nil, preset.hex)
    }
}
