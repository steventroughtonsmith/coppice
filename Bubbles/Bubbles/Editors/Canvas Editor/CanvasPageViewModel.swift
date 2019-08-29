//
//  CanvasPageViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasPageView: class {
}

class CanvasPageViewModel: NSObject {
    weak var view: CanvasPageView?

    let canvasPage: CanvasPage
    init(canvasPage: CanvasPage) {
        self.canvasPage = canvasPage
        super.init()
    }
}

