//
//  NSViewController+M3Extensions.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSViewController {
    var windowController: NSWindowController? {
        return self.view.window?.windowController
    }
}
