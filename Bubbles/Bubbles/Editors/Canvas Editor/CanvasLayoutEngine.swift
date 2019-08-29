//
//  CanvasLayoutEngine.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasView {
    func add(_ pageView: PageLayoutModel)
    func remove(_ pageView: PageLayoutModel)

    func update(_ pageViews: [PageLayoutModel])
}

class PageLayoutModel {
    let id: ModelID
    var xOffset: CGFloat {
        didSet { self.hasChanged = true }
    }
    var yOffset: CGFloat {
        didSet { self.hasChanged = true }
    }
    var width: CGFloat {
        didSet { self.hasChanged = true }
    }
    var height: CGFloat {
        didSet { self.hasChanged = true }
    }

    private(set) var hasChanged = false

    init(canvasPage: CanvasPage) {
        self.id = canvasPage.id
        self.xOffset = canvasPage.position.x
        self.yOffset = canvasPage.position.y
        self.width = canvasPage.size.width
        self.height = canvasPage.size.height
    }

    func appliedChanges() {
        self.hasChanged = false
    }

    static func == (lhs: PageLayoutModel, rhs: PageLayoutModel) -> Bool {
        return lhs.id == rhs.id
    }
}


protocol CanvasLayoutEngineDelegate: class {
    func canvasResized(to size: CGSize, by layoutEngine: CanvasLayoutEngine)
    func canvasOriginOffsetChanged(to point: CGPoint, by layoutEngine: CanvasLayoutEngine)
    func position(ofPageWithID pageID: ModelID, updatedTo to: CGPoint, by layoutEngine: CanvasLayoutEngine)
    func size(ofPageWithID pageID: ModelID, updatedTo to: CGSize, by layoutEngine: CanvasLayoutEngine)
}


class CanvasLayoutEngine: NSObject {
    enum EventType {
        case move
        case resize
    }
    
    weak var delegate: CanvasLayoutEngineDelegate?

    //MARK: - Canvas Info
    var canvasView: CanvasView?
    private var canvasSize: CGSize = .zero
    private var canvasOrigin: CGPoint = .zero

    private(set) var pages = [PageLayoutModel]()

    func add(_ canvasPages: [CanvasPage], atLocation location: CGPoint? = nil) {
//        let layoutModel = PageLayoutModel(canvasPage: canvasPage)
//        self.pages.append(layoutModel)
//        self.canvasView?.add(layoutModel)
//        self.setNeedsCanvasLayout()

        //Adding logic
        // Two ways to add: with a location and without a location
        // With a location should centre on that location
        // Without a location should use the first clear space to the right or bottom of the canvas
        //For multiple items, they should be stacked below and to the right so that the title bars are visible
    }

    private func initialPositionForNewPage(of size: CGSize) -> CGPoint {
        return .zero
    }

    func remove(_ canvasPages: [CanvasPage]) {
        for page in canvasPages {
            self.remove(page)
        }
    }

    private func remove(_ canvasPage: CanvasPage) {
        guard let indexToDelete = self.pages.firstIndex(where: { $0.id == canvasPage.id }) else {
            return
        }
        let model = self.pages[indexToDelete]
        self.pages.remove(at: indexToDelete)
        self.canvasView?.remove(model)
        for child in canvasPage.children {
            self.remove(child)
        }
        self.setNeedsCanvasLayout()
    }

    func setNeedsCanvasLayout() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(layoutCanvas), object: nil)
        self.perform(#selector(layoutCanvas), with: nil, afterDelay: 0)
    }

    @objc func layoutCanvas() {
        //Position canvas
        //Find

        self.canvasView?.update(self.pages.filter { $0.hasChanged })
    }

    func eventType(forLocation location: CGPoint) -> EventType? {
        return nil
    }

    //Modification
    func startEvent(on canvasPage: PageLayoutModel, location: CGPoint) {

    }

    func continueEvent(on canvasPage: PageLayoutModel, location: CGPoint) {

    }

    func endEvent(on canvasPage: PageLayoutModel, location: CGPoint) {

    }
}



