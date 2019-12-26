//
//  ImageEditorInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 03/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "ImageEditorInspectorContentView"
    }

    override var ranking: InspectorRanking { return .content }
}
