//
//  SidebarCanvasViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class SidebarCanvasViewModel: NSObject {
    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()
    }

    var numberOfCanvases: Int {
        return self.modelController.allCanvases.count
    }

    func canvas(forRow row: Int) -> Canvas {
        return self.modelController.allCanvases[row]
    }

    //MARK: - Selection
    var selectedRow: Int = -1

    var selectedCanvas: Canvas? {
        guard self.selectedRow >= 0 else {
            return nil
        }
        return self.canvas(forRow: self.selectedRow)
    }
}
