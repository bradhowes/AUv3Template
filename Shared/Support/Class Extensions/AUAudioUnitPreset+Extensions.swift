// Copyright © 2021 Brad Howes. All rights reserved.

import AVFoundation

internal extension AUAudioUnitPreset {
  /**
   Initialize new instance with given values

   - parameter number: the unique number for this preset. Factory presets must be non-negative.
   - parameter name: the display name for the preset.
   */
  convenience init(number: Int, name: String) {
    self.init()
    self.number = number
    self.name = name
  }
}

public extension AUAudioUnitPreset {
  override var description: String { "<AuAudioUnitPreset name: \(name)/\(number)>" }
}
