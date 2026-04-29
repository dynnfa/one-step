import OSLog

public enum OneStepLog {
    public static let subsystem = "dev.dynnfa.OneStep"
    public static let repository = Logger(subsystem: subsystem, category: "repository")
    public static let widget = Logger(subsystem: subsystem, category: "widget")
    public static let appIntent = Logger(subsystem: subsystem, category: "app-intent")
    public static let store = Logger(subsystem: subsystem, category: "store")
}
