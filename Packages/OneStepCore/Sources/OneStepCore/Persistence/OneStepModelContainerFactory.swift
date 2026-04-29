import Foundation
import SwiftData

public enum OneStepModelContainerFactory {
    public static let storeFileName = "OneStep.sqlite"

    public static func makeInMemory() throws -> ModelContainer {
        let schema = Schema([Goal.self, DailyCompletion.self])
        let configuration = ModelConfiguration("OneStepTests", schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func makeShared(appGroupIdentifier: String) throws -> ModelContainer {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw GoalRepositoryError.storeUnavailable
        }
        let url = storeURL(appGroupContainerURL: appGroupURL)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let schema = Schema([Goal.self, DailyCompletion.self])
        let configuration = ModelConfiguration("OneStep", schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func storeURL(appGroupContainerURL: URL) -> URL {
        appGroupContainerURL
            .appending(path: "OneStep", directoryHint: .isDirectory)
            .appending(path: storeFileName)
    }
}
