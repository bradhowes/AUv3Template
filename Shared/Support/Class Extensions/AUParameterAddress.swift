// Copyright © 2021 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameterAddress {
  var filterParameter: FilterParameterAddress? { FilterParameterAddress(rawValue: self) }
}
