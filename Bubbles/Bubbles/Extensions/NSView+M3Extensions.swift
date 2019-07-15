//
//  NSView+M3Extensions.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSView {
    func addSubview(_ subview: NSView, withInsets insets: NSEdgeInsets) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)

        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "|-(left)-[view]-(right)-|",
                                                         options: [],
                                                         metrics: ["left": NSNumber(value: Double(insets.left)), "right": NSNumber(value: Double(insets.right))],
                                                         views: ["view": subview])
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(top)-[view]-(bottom)-|",
                                                     options: [],
                                                     metrics: ["top": NSNumber(value: Double(insets.top)), "bottom": NSNumber(value: Double(insets.bottom))],
                                                     views: ["view": subview])
        NSLayoutConstraint.activate(constraints)
    }
}
