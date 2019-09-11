//
//  TestCanvasPageViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

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
        self.width = canvasPage.size.width
        self.height = canvasPage.size.height
        self.position = canvasPage.position
        super.init(nibName: "TestCanvasPageViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateFrame()
    }

    private func updateFrame() {
        self.view.frame = CGRect(x: self.position.x, y: self.position.y, width: self.width, height: self.height)
    }
}
