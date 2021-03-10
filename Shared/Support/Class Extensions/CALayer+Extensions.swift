// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

extension CALayer {

    public convenience init(color: Color, frame: CGRect) {
        self.init()
        backgroundColor = color.cgColor
        self.frame = frame
    }
}
