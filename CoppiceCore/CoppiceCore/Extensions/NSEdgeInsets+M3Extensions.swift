//
//  Foundation+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension NSEdgeInsets {
    public var horizontalInsets: CGFloat {
        return self.left + self.right
    }

    public var verticalInsets: CGFloat {
        return self.top + self.bottom
    }

    public var inverted: NSEdgeInsets {
        return NSEdgeInsets(top: -self.top, left: -self.left, bottom: -self.bottom, right: -self.right)
    }
}
