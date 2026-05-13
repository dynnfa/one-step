import Foundation

public struct LocalDay: Hashable, Codable, RawRepresentable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard LocalDay.isValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }

    public init(date: Date = Date(), calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.rawValue = String(
            format: "%04d-%02d-%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    public static var today: LocalDay {
        LocalDay()
    }

    public func days(until other: LocalDay) -> Int {
        guard let startDate = LocalDay.date(from: rawValue),
              let endDate = LocalDay.date(from: other.rawValue)
        else { return 0 }
        return LocalDay.calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    private static func isValid(_ value: String) -> Bool {
        guard value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            return false
        }
        return date(from: value) != nil
    }

    private static func date(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value)
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
