//
//  ImageEditorView.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorView: EditorBackgroundView {
    @IBOutlet var imageView: NSImageView?

    override func hitTest(_ point: NSPoint) -> NSView? {
        return self.imageView;
    }
}
