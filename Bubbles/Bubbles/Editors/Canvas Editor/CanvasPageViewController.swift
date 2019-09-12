//
//  CanvasPageViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasPageViewController: NSViewController {

    var uuid: UUID {
        return self.viewModel.canvasPage.id.uuid
    }

    var typedView: ResizableCanvasElement {
        get { self.view as! ResizableCanvasElement }
        set { self.view = newValue }
    }

    let viewModel: CanvasPageViewModel
    init(viewModel: CanvasPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasPageViewController", bundle: nil)
//        viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CanvasPageViewController: LayoutPageComponentProvider {
    func component(at point: CGPoint, in page: LayoutEnginePage) -> LayoutEnginePageComponent? {
        self.typedView.component(at: point)
    }
}
