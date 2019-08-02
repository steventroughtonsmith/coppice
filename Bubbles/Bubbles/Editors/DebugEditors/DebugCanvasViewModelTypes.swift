//
//  DebugCanvasViewModelTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

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
        get { self.canvasPage.position.x }
        set { self.canvasPage.position.x = newValue }
    }

    var y: CGFloat {
        get { self.canvasPage.position.y }
        set { self.canvasPage.position.y = newValue }
    }

    var width: CGFloat {
        get { self.canvasPage.size.width }
        set { self.canvasPage.size.width = newValue }
    }

    var height: CGFloat {
        get { self.canvasPage.size.height }
        set { self.canvasPage.size.height = newValue }
    }

    var parentID: String {
        get { self.canvasPage.parent?.id.uuid.uuidString ?? "" }
        set {
            guard let id = CanvasPage.modelID(withUUIDString: newValue),
                  id != self.canvasPage.id else {
                self.canvasPage.parent = nil
                return
            }

            self.canvasPage.parent = self.canvasPage.collection?.objectWithID(id)
        }
    }
}
