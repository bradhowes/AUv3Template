// Copyright © 2021 Brad Howes. All rights reserved.

extension Comparable {

    /**
     Make sure that a value falls within a given range, forcing it to be at either extreme if it is outside of the
     range.

     @param range the limits to check against
     @returns clamped value
     */
    public func clamp(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}
