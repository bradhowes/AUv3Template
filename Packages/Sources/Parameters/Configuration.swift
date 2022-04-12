// Copyright © 2021 Brad Howes. All rights reserved.

import AudioUnit

public struct Configuration {
  public let depth: AUValue
  public let rate: AUValue
  public let delay: AUValue
  public let feedback: AUValue
  public let dry: AUValue
  public let wet: AUValue
  public let negativeFeedback: AUValue
  public let odd90: AUValue

  public init(depth: AUValue, rate: AUValue, delay: AUValue, feedback: AUValue, dry: AUValue, wet: AUValue,
              negativeFeedback: AUValue, odd90: AUValue) {
    self.depth = depth
    self.rate = rate
    self.delay = delay
    self.feedback = feedback
    self.dry = dry
    self.wet = wet
    self.negativeFeedback = negativeFeedback
    self.odd90 = odd90
  }
}
