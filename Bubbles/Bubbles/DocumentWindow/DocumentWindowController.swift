//
//  DocumentWindowController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 09/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DocumentWindowController: NSWindowController {
    @IBOutlet weak var splitView: NSSplitView!

    @IBOutlet weak var sidebarContainer: NSView!
    @IBOutlet weak var editorContainer: NSView!
    @IBOutlet weak var inspectorContainer: NSView!


    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
