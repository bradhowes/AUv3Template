// Copyright © 2020 Brad Howes. All rights reserved.

public extension DispatchQueue {
  /**
   Perform an operation synchronously if already on the main thread. Otherwise, dispatch it to a queue to run
   asynchronously on the main thread.

   - parameter operation: the block to run
   */
  static func performOnMain(_ operation: @escaping () -> Void) {
    if Thread.isMainThread {
      operation()
    } else {
      DispatchQueue.main.async { operation() }
    }
  }
}
