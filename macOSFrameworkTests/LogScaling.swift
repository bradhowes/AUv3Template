// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest

class LogScalingTests: XCTestCase {
  let minHertz = Float(12)
  let maxHertz = Float(20000)
  lazy var hertzScale = log2f(maxHertz / minHertz)

  func testPositionToFrequency() throws {
    let p0 = CGFloat(0)
    let width = CGFloat(200)

    let v0 = minHertz * pow(2, Float(p0 / width) * hertzScale)
    XCTAssertEqual(minHertz, v0, accuracy: 0.00001)

    let v1 = minHertz * pow(2, Float(width / width) * hertzScale)
    XCTAssertEqual(maxHertz, v1, accuracy: 0.1)

    let v2 = minHertz * pow(2, 0.5 * hertzScale)
    XCTAssertEqual(v2, 489.898, accuracy: 0.1)
  }

  func testFrequencyToPosition() throws {
    let width = CGFloat(200)

    let v0 = minHertz
    let p0 = CGFloat(log2(Float(v0) / minHertz) * Float(width) / hertzScale)
    XCTAssertEqual(p0, 0, accuracy: 0.00001)

    let v1 = maxHertz
    let p1 = CGFloat(log2(Float(v1) / minHertz) * Float(width) / hertzScale)
    XCTAssertEqual(p1, width, accuracy: 0.00001)
  }
}
