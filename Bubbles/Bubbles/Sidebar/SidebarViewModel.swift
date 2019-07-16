//
//  SidebarViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol SidebarView: class {
    func reloadSelection()
    func reloadCanvases()
    func reloadPages()
}

protocol SidebarViewModelDelegate: class {
    func selectedObjectDidChange(in viewModel: SidebarViewModel)
}

class SidebarViewModel: NSObject {
    weak var view: SidebarView?
    weak var delegate: SidebarViewModelDelegate?

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

    var numberOfPages: Int {
        return self.modelController.allPages.count
    }

    func page(forRow row: Int) -> Page {
        return self.modelController.allPages[row]
    }

    //MARK: - Selection
    var selectedObject: Any? {
        if (self.selectedCanvasRow >= 0) {
            return self.modelController.allCanvases[self.selectedCanvasRow]
        }
        if (self.selectedPageRow >= 0) {
            return self.modelController.allPages[self.selectedPageRow]
        }
        return nil
    }


    private(set) var selectedCanvasRow: Int = -1

    func selectCanvas(atRow row: Int) {
        guard self.selectedCanvasRow != row else {
            return
        }

        self.selectedPageRow = -1
        self.selectedCanvasRow = row
        self.view?.reloadSelection()
        self.delegate?.selectedObjectDidChange(in: self)
    }

    private(set) var selectedPageRow: Int = -1

    func selectPage(atRow row: Int) {
        guard self.selectedPageRow != row else {
            return
        }

        self.selectedCanvasRow = -1
        self.selectedPageRow = row
        self.view?.reloadSelection()
        self.delegate?.selectedObjectDidChange(in: self)
    }
}
