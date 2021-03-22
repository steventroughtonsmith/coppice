//
//  PageArrowView.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class PageArrowView: NSView {
    var arrow: LayoutEngineArrow? {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    var lineColour: NSColor = .black {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    let config: CanvasLayoutEngine.Configuration.Arrow
    private let drawHelper: ArrowDrawHelper
    init(config: CanvasLayoutEngine.Configuration.Arrow) {
        self.config = config
        self.drawHelper = ArrowDrawHelper(config: config)
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let arrow = self.arrow else {
            return
        }

        self.drawHelper.draw(arrow, with: self.lineColour)
    }
}
