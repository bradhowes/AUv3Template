// Copyright © 2021 Brad Howes. All rights reserved.

extension CATransaction {

    /**
     Execute a block within a CATransaction that has animation disabled.

     @param block the closure to run inside of a CATransaction.
     */
    public class func noAnimation(_ block: () -> Void) {
        defer { CATransaction.commit() }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        block()
    }
}
