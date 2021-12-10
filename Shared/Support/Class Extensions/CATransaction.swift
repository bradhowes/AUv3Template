// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

public extension CATransaction {
  /**
   Execute a block within a CATransaction that has animation disabled.

   @param block the closure to run inside of a CATransaction.
   */
  class func noAnimation(_ block: () -> Void) {
    defer { CATransaction.commit() }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    block()
  }
}
