import Foundation
import SwiftData

public enum OneStepModelContainerFactory {
    public static let storeFileName = "OneStep.sqlite"

    private static var sharedContainers: [String: ModelContainer] = [:]

    public static func sharedContainer(appGroupIdentifier: String) throws -> ModelContainer {
        if let existing = sharedContainers[appGroupIdentifier] { return existing }
        let container = try makeShared(appGroupIdentifier: appGroupIdentifier)
        sharedContainers[appGroupIdentifier] = container
        return container
    }

    public static func makeInMemory() throws -> ModelContainer {
        let schema = Schema([FinalGoal.self, MilestoneGoal.self, DailyCompletion.self])
        let configuration = ModelConfiguration("OneStepTests", schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func makeShared(appGroupIdentifier: String) throws -> ModelContainer {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw GoalRepositoryError.storeUnavailable
        }
        let url = storeURL(appGroupContainerURL: appGroupURL)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let schema = Schema([FinalGoal.self, MilestoneGoal.self, DailyCompletion.self])
        let configuration = ModelConfiguration("OneStep", schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func storeURL(appGroupContainerURL: URL) -> URL {
        appGroupContainerURL
            .appending(path: "OneStep", directoryHint: .isDirectory)
            .appending(path: storeFileName)
    }
}
