//
//  DebugCanvasViewModelTypes.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import CoppiceCore
import Foundation

class DebugCanvasPageItem {
    let canvasPage: CanvasPage
    init(canvasPage: CanvasPage) {
        self.canvasPage = canvasPage
    }

    var id: String {
        return self.canvasPage.id.uuid.uuidString
    }

    var pageTitle: String {
        get { self.canvasPage.page?.title ?? "" }
        set { self.canvasPage.page?.title = newValue }
    }

    var x: CGFloat {
        get { self.canvasPage.frame.origin.x }
        set { self.canvasPage.frame.origin.x = newValue }
    }

    var y: CGFloat {
        get { self.canvasPage.frame.origin.y }
        set { self.canvasPage.frame.origin.y = newValue }
    }

    var width: CGFloat {
        get { self.canvasPage.frame.size.width }
        set { self.canvasPage.frame.size.width = newValue }
    }

    var height: CGFloat {
        get { self.canvasPage.frame.size.height }
        set { self.canvasPage.frame.size.height = newValue }
    }

    var parentID: String {
        get { self.canvasPage.parent?.id.uuid.uuidString ?? "" }
        set {
            guard let id = CanvasPage.modelID(withUUIDString: newValue),
                  id != self.canvasPage.id
            else {
                self.canvasPage.parent = nil
                return
            }

            self.canvasPage.parent = self.canvasPage.collection?.objectWithID(id)
        }
    }
}
