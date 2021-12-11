// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os.log

extension FourCharCode: ExpressibleByStringLiteral {
  /**
   Allow creation from a string literal. The literal must consist of 4 ASCII characters.

   - parameter value: the string literal to use
   */
  public init(stringLiteral value: StringLiteralType) {
    guard value.utf8.count == 4 else {
      os_log(.error, "FourCharCode: invalid string '%s'. Setting to '????'.", value)
      self = 0x3F3F3F3F // = '????'
      return
    }

    var code: FourCharCode = 0
    for byte in value.utf8 {
      code = code << 8 + FourCharCode(byte)
    }
    self = code
  }

  /**
   Allow creation from a string literal. The literal must consist of 4 ASCII characters.

   - parameter value: the string literal to use
   */
  public init(extendedGraphemeClusterLiteral value: String) {
    self = FourCharCode(stringLiteral: value)
  }

  /**
   Allow creation from a string literal. The literal must consist of 4 ASCII characters.

   - parameter value: the string literal to use
   */
  public init(unicodeScalarLiteral value: String) {
    self = FourCharCode(stringLiteral: value)
  }

  /**
   Allow creation from a string literal. The literal must consist of 4 ASCII characters.

   - parameter value: the string to use
   */
  public init(_ value: String) {
    self = FourCharCode(stringLiteral: value)
  }
}

extension FourCharCode {
  private static let bytesSizeForStringValue = MemoryLayout<Self>.size

  /// Obtain a 4-character string from our value - based on https://stackoverflow.com/a/60367676/629836
  public var stringValue: String {
    withUnsafePointer(to: bigEndian) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: Self.bytesSizeForStringValue) { bytes in
        String(bytes: UnsafeBufferPointer(start: bytes, count: Self.bytesSizeForStringValue),
               encoding: .macOSRoman) ?? "????"
      }
    }
  }
}
