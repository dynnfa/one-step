import XCTest
@testable import OneStepCore

final class OneStepCoreSmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(OneStepCore.moduleName, "OneStepCore")
    }
}
