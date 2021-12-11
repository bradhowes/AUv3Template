// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import Foundation

public extension CALayer {
  convenience init(color: Color, frame: CGRect) {
    self.init()
    backgroundColor = color.cgColor
    self.frame = frame
  }
}
