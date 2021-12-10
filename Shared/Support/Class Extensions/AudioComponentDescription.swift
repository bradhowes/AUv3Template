// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import os

public extension AudioComponentDescription {
  func log(_ logger: OSLog, type: OSLogType) {
    os_log(type, log: logger,
           "AudioComponentDescription type: %{public}s, subtype: %{public}s, manufacturer: %{public}s flags: %x (%x)",
           componentType.stringValue,
           componentSubType.stringValue,
           componentManufacturer.stringValue,
           componentFlags,
           componentFlagsMask)
  }
}
