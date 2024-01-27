import XCTest
import AUv3Support
import Kernel
import Parameters
import ParameterAddress

final class ParameterTests: XCTestCase {

  func testParameterAddress() throws {
    XCTAssertEqual(ParameterAddress.depth.rawValue, 0)
    XCTAssertEqual(ParameterAddress.odd90.rawValue, 7)

    // Unfortunately, there is no init? for Obj-C enums
    // XCTAssertNil(ParameterAddress(rawValue: ParameterAddress.odd90.rawValue + 1))

    XCTAssertEqual(ParameterAddress.allCases.count, 8)
    XCTAssertTrue(ParameterAddress.allCases.contains(.depth))
    XCTAssertTrue(ParameterAddress.allCases.contains(.rate))
    XCTAssertTrue(ParameterAddress.allCases.contains(.delay))
    XCTAssertTrue(ParameterAddress.allCases.contains(.feedback))
    XCTAssertTrue(ParameterAddress.allCases.contains(.dry))
    XCTAssertTrue(ParameterAddress.allCases.contains(.wet))
    XCTAssertTrue(ParameterAddress.allCases.contains(.negativeFeedback))
    XCTAssertTrue(ParameterAddress.allCases.contains(.odd90))
  }

  func testParameterDefinitions() throws {
    let aup = Parameters()
    for (index, address) in ParameterAddress.allCases.enumerated() {
      XCTAssertTrue(aup.parameters[index] == aup[address])
    }
  }
}
