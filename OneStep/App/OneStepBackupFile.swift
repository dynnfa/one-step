import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let oneStepBackup = UTType("com.onestep.backup") ?? UTType(exportedAs: "com.onestep.backup", conformingTo: .json)
}

struct OneStepBackupFile: FileDocument, Equatable {
    static var readableContentTypes: [UTType] { [.oneStepBackup, .json] }
    static var writableContentTypes: [UTType] { [.oneStepBackup] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        try self.init(fileWrapper: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        makeFileWrapper()
    }

    init(fileWrapper: FileWrapper) throws {
        guard let data = fileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func makeFileWrapper() -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
