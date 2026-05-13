import XCTest
@testable import OneStepCore

final class OneStepBackupDocumentTests: XCTestCase {
    func testBackupDocumentRoundTripsThroughJSON() throws {
        let finalGoalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let milestoneID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let completionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let createdAt = Date(timeIntervalSince1970: 1_777_000_000)
        let updatedAt = Date(timeIntervalSince1970: 1_777_000_060)

        let document = OneStepBackupDocument(
            exportedAt: Date(timeIntervalSince1970: 1_777_000_120),
            finalGoals: [
                OneStepBackupDocument.FinalGoalRecord(
                    id: finalGoalID,
                    title: "Pass IELTS",
                    goalDescription: "Score 7.0+",
                    targetCalendarDays: 180,
                    colorThemeID: FinalGoalColorTheme.green.id,
                    customColorHex: nil,
                    startDayKey: "2026-04-29",
                    sortOrder: 0,
                    archivedAt: nil,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            ],
            milestones: [
                OneStepBackupDocument.MilestoneGoalRecord(
                    id: milestoneID,
                    title: "Listening practice",
                    targetCompletionTimes: 30,
                    finalGoalID: finalGoalID,
                    sortOrder: 0,
                    isActive: true,
                    startDayKey: "2026-04-29",
                    completedAt: nil,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            ],
            dailyCompletions: [
                OneStepBackupDocument.DailyCompletionRecord(
                    id: completionID,
                    goalID: milestoneID,
                    dayKey: "2026-04-29",
                    completedAt: updatedAt
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(OneStepBackupDocument.self, from: data)

        XCTAssertEqual(decoded, document)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(json.contains("\"schemaVersion\" : 1"))
        XCTAssertTrue(json.contains("\"finalGoals\""))
        XCTAssertTrue(json.contains("\"colorThemeID\" : \"green\""))
        XCTAssertTrue(json.contains("\"targetCompletionTimes\" : 30"))
        XCTAssertTrue(json.contains("\"milestones\""))
        XCTAssertTrue(json.contains("\"dailyCompletions\""))
    }

    func testLegacyMilestoneTargetCompletionDaysDecodesAsTimes() throws {
        let json = """
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "title": "Legacy milestone",
          "targetCompletionDays": 12,
          "finalGoalID": "11111111-1111-1111-1111-111111111111",
          "sortOrder": 0,
          "isActive": true,
          "startDayKey": null,
          "completedAt": null,
          "createdAt": "2026-04-29T00:00:00Z",
          "updatedAt": "2026-04-29T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let record = try decoder.decode(OneStepBackupDocument.MilestoneGoalRecord.self, from: Data(json.utf8))

        XCTAssertEqual(record.targetCompletionTimes, 12)
    }

    func testUnlimitedMilestoneEncodesTargetCompletionTimesNull() throws {
        let record = OneStepBackupDocument.MilestoneGoalRecord(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Open-ended",
            targetCompletionTimes: nil,
            finalGoalID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            sortOrder: 0,
            isActive: true,
            startDayKey: nil,
            completedAt: nil,
            createdAt: Date(timeIntervalSince1970: 1_777_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_777_000_000)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(record)

        let json = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(json.contains("\"targetCompletionTimes\" : null"))
    }

    func testBackupErrorDescriptionsAreUserFacing() {
        XCTAssertEqual(OneStepBackupError.unsupportedSchemaVersion(99).localizedDescription, "This backup uses schema version 99, which this version of One Step cannot import.")
        XCTAssertEqual(OneStepBackupError.invalidFinalGoalTitle.localizedDescription, "A final goal in the backup has an empty title.")
        XCTAssertEqual(OneStepBackupError.duplicateDailyCompletion.localizedDescription, "The backup contains duplicate daily completions for the same milestone and day.")
    }
}
