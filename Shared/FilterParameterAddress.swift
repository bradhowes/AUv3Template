// Copyright © 2021 Apple. All rights reserved.

import Foundation

/**
 Address definitions for AUParameter settings.
 */
@objc public enum FilterParameterAddress: UInt64, CaseIterable {
  case depth = 0
  case rate
  case delay
  case feedback
  case dryMix
  case wetMix
}

public extension Array where Element == AUParameter {
  subscript(index: FilterParameterAddress) -> AUParameter { self[Int(index.rawValue)] }
}
