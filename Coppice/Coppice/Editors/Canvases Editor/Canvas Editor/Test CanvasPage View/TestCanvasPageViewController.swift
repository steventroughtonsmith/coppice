//
//  TestCanvasPageViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class TestCanvasPageViewController: NSViewController {
    let id: UUID
    var width: CGFloat {
        didSet { self.updateFrame() }
    }

    var height: CGFloat {
        didSet { self.updateFrame() }
    }

    var position: CGPoint {
        didSet { self.updateFrame() }
    }

    let canvasPage: CanvasPage
    init(canvasPage: CanvasPage) {
        self.canvasPage = canvasPage
        self.id = canvasPage.id.uuid
        self.width = canvasPage.frame.size.width
        self.height = canvasPage.frame.size.height
        self.position = canvasPage.frame.origin
        super.init(nibName: "TestCanvasPageViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateFrame()
    }

    private func updateFrame() {
        self.view.frame = CGRect(x: self.position.x, y: self.position.y, width: self.width, height: self.height)
    }
}
