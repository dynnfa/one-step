import XCTest
@testable import OneStepCore

final class OneStepLogTests: XCTestCase {
    func testSubsystemUsesOneStepBundleNamespace() {
        XCTAssertEqual(OneStepLog.subsystem, "dev.dynnfa.OneStep")
    }
}
