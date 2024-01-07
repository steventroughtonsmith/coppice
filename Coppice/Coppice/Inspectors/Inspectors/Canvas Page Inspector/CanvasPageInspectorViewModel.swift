//
//  CanvasPageInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import CoppiceCore
import Foundation
import M3Data

class CanvasPageInspectorViewModel: BaseInspectorViewModel {
    let canvasPage: CanvasPage
    let modelController: ModelController

    init(canvasPage: CanvasPage, modelController: ModelController) {
        self.canvasPage = canvasPage
        self.modelController = modelController

        super.init()

        self.subscribers[.frame] = canvasPage.changePublisher(for: \.frame)?.sink { [weak self] _ in
            self?.notifyOfChange(to: \.width)
            self?.notifyOfChange(to: \.height)
        }
    }

    override var title: String? {
        return NSLocalizedString("Page Layout", comment: "Page layout inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.canvaspage"
    }

    var widthToHeightAspectRatio: CGFloat? {
        if let page = canvasPage.page, page.content.maintainAspectRatio {
            return self.canvasPage.frame.width / self.canvasPage.frame.height
        } else {
            return nil
        }
    }

    @objc dynamic var width: Int {
        get { Int(self.canvasPage.frame.width) }
        set {
            var size = self.canvasPage.frame.size
            size.width = CGFloat(max(newValue, self.minimumWidth))
            if let aspectRatio = self.widthToHeightAspectRatio {
                size.height = size.width / aspectRatio
                if size.height < CGFloat(self.minimumHeight) {
                    size.height = CGFloat(self.minimumHeight)
                    size.width = size.height * aspectRatio
                }
            }

            self.canvasPage.frame.size = size

            if Int(size.width) != newValue {
                //We need to inform the bindings to update as it doesn't observe for changes if it is the one that is editing
                self.perform(#selector(willChangeValue(forKey:)), with: #keyPath(width), afterDelay: 0)
                self.perform(#selector(didChangeValue(forKey:)), with: #keyPath(width), afterDelay: 0)
            }
        }
    }

    @objc dynamic var height: Int {
        get { Int(self.canvasPage.frame.height) }
        set {
            var size = self.canvasPage.frame.size
            size.height = CGFloat(max(newValue, self.minimumHeight))
            if let aspectRatio = self.widthToHeightAspectRatio {
                size.width = size.height * aspectRatio
                if size.width < CGFloat(self.minimumWidth) {
                    size.width = CGFloat(self.minimumWidth)
                    size.height = size.width / aspectRatio
                }
            }

            self.canvasPage.frame.size = size

            if Int(size.height) != newValue {
                //See .width
                self.perform(#selector(willChangeValue(forKey:)), with: #keyPath(height), afterDelay: 0)
                self.perform(#selector(didChangeValue(forKey:)), with: #keyPath(height), afterDelay: 0)
            }
        }
    }

    @objc dynamic var minimumWidth: Int {
        return Int(self.canvasPage.minimumContentSize.width)
    }

    @objc dynamic var minimumHeight: Int {
        return Int(self.canvasPage.minimumContentSize.height)
    }

    func sizeToFitContent() {
        guard let page = self.canvasPage.page else {
            return
        }
        self.canvasPage.frame.size = page.content.sizeToFitContent(currentSize: self.canvasPage.frame.size)
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case frame
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}
