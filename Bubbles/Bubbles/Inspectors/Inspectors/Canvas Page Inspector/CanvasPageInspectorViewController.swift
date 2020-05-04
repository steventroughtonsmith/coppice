//
//  CanvasPageInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasPageInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "CanvasPageInspectorContentView"
    }

    var typedViewModel: CanvasPageInspectorViewModel {
        return self.viewModel as! CanvasPageInspectorViewModel
    }

    override var ranking: InspectorRanking { return .canvasPage }

    @IBAction func sizeToFitContent(_ sender: Any) {
        self.typedViewModel.sizeToFitContent()
    }
}
