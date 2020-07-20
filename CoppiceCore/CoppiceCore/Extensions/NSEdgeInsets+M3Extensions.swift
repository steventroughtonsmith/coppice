//
//  Foundation+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public extension NSEdgeInsets {
    var horizontalInsets: CGFloat {
        return self.left + self.right
    }

    var verticalInsets: CGFloat {
        return self.top + self.bottom
    }
}
