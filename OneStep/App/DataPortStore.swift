import Foundation
import Observation
import OneStepCore
import WidgetKit

@MainActor
@Observable
final class DataPortStore {
    private let repository: OneStepBackupRepository

    var statusMessage: String?
    var errorMessage: String?

    init(repository: OneStepBackupRepository) {
        self.repository = repository
    }

    static func live() throws -> DataPortStore {
        DataPortStore(repository: try OneStepBackupRepository.shared(appGroupIdentifier: AppIdentifiers.appGroupIdentifier))
    }

    func makeExportFile() -> OneStepBackupFile? {
        do {
            let document = try repository.exportDocument()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(document)
            statusMessage = "Export is ready."
            errorMessage = nil
            return OneStepBackupFile(data: data)
        } catch {
            statusMessage = nil
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func importData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let document = try decoder.decode(OneStepBackupDocument.self, from: data)
            try repository.importDocument(document)
            WidgetCenter.shared.reloadTimelines(ofKind: AppIdentifiers.widgetKind)
            statusMessage = "Import complete."
            errorMessage = nil
        } catch let backupError as OneStepBackupError {
            statusMessage = nil
            errorMessage = backupError.localizedDescription
        } catch let decodingError as DecodingError {
            statusMessage = nil
            errorMessage = OneStepBackupError.decodeFailed(decodingError.localizedDescription).localizedDescription
        } catch {
            statusMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    static func defaultExportFilename(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return "OneStep-Backup-\(formatter.string(from: now)).oneStepBackup"
    }
}
