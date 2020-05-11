//
//  CanvasInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "CanvasInspectorContentView"
    }

    override var ranking: InspectorRanking { return .canvas }
}
