import XCTest
import AUv3Support
import Kernel
import Parameters
import ParameterAddress

class MockParameterHandler: AUParameterHandler {
  var mapping = [AUParameterAddress: AUValue]()
  func set(_ parameter: AUParameter, value: AUValue) { mapping[parameter.address] = value }
  func get(_ parameter: AUParameter) -> AUValue { mapping[parameter.address] ?? 0.0 }
}

final class FilterPresetTests: XCTestCase {

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
    let aup = AudioUnitParameters()
    for (index, address) in ParameterAddress.allCases.enumerated() {
      XCTAssertTrue(aup.parameters[index] == aup[address])
    }
  }
}
