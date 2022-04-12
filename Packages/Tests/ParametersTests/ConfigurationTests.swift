import XCTest
@testable import Parameters

final class ConfigurationTests: XCTestCase {

  func testInit() throws {
    
    let a = Configuration(depth: 1.0, rate: 2.0, delay: 3.0, feedback: 4.0, dry: 5.0, wet: 6.0,
                         negativeFeedback: 1.0, odd90: 0.0)

    XCTAssertEqual(a.depth, 1.0)
    XCTAssertEqual(a.rate, 2.0)
    XCTAssertEqual(a.delay, 3.0)
    XCTAssertEqual(a.feedback, 4.0)
    XCTAssertEqual(a.dry, 5.0)
    XCTAssertEqual(a.wet, 6.0)
    XCTAssertEqual(a.negativeFeedback, 1.0)
    XCTAssertEqual(a.odd90, 0.0)
  }
}
