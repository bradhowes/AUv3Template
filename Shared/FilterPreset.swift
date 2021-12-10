// Copyright © 2021 Brad Howes. All rights reserved.

import AudioUnit
import Foundation

public struct FilterPreset {
  let depth: AUValue
  let rate: AUValue
  let delay: AUValue
  let feedback: AUValue
  let dryMix: AUValue
  let wetMix: AUValue
}
