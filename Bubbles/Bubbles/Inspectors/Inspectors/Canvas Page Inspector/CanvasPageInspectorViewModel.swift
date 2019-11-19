//
//  CanvasPageInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class CanvasPageInspectorViewModel: BaseInspectorViewModel {
    @objc dynamic let canvasPage: CanvasPage
    let modelController: ModelController
    init(canvasPage: CanvasPage, modelController: ModelController) {
        self.canvasPage = canvasPage
        self.modelController = modelController
        super.init()
    }

    override var title: String? {
        return NSLocalizedString("Page Layout", comment: "Page layout inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.canvaspage"
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if ((key == #keyPath(width)) || key == #keyPath(height)) {
            keyPaths.insert("canvasPage.frame")
        }
        return keyPaths
    }

    @objc dynamic var width: Int {
        get { Int(self.canvasPage.frame.width) }
        set {
            if newValue > self.minimumWidth {
                self.canvasPage.frame.size.width = CGFloat(newValue)
            } else {
                self.canvasPage.frame.size.width = CGFloat(self.minimumWidth)
                //We need to inform the bindings to update as it doesn't observe for changes if it is the one that is editing
                self.perform(#selector(willChangeValue(forKey:)), with: #keyPath(width), afterDelay: 0)
                self.perform(#selector(didChangeValue(forKey:)), with: #keyPath(width), afterDelay: 0)
            }
        }
    }

    @objc dynamic var height: Int {
        get { Int(self.canvasPage.frame.height) }
        set {
            if newValue > self.minimumHeight {
                self.canvasPage.frame.size.height = CGFloat(newValue)
            } else {
                self.canvasPage.frame.size.height = CGFloat(self.minimumHeight)
                //See .width
                self.perform(#selector(willChangeValue(forKey:)), with: #keyPath(height), afterDelay: 0)
                self.perform(#selector(didChangeValue(forKey:)), with: #keyPath(height), afterDelay: 0)
            }
        }
    }

    @objc dynamic var minimumWidth: Int {
        return Int(GlobalConstants.minimumPageSize.width)
    }

    @objc dynamic var minimumHeight: Int {
        return Int(GlobalConstants.minimumPageSize.height)
    }
}
