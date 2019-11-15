//
//  CanvasInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasInspectorView: class {

}


class CanvasInspectorViewModel: NSObject {
    weak var view: CanvasInspectorView?

    let canvas: Canvas
    let modelController: ModelController
    init(canvas: Canvas, modelController: ModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()
    }
}
