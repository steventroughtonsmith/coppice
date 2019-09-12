//
//  LayoutEnginePage.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

enum LayoutEnginePageComponent: CaseIterable, Equatable {
    case titleBar
    case resizeLeft
    case resizeTopLeft
    case resizeTop
    case resizeTopRight
    case resizeRight
    case resizeBottomRight
    case resizeBottom
    case resizeBottomLeft

    var isRight: Bool {
        return [.resizeRight, .resizeTopRight, .resizeBottomRight].contains(self)
    }

    var isBottom: Bool {
        return [.resizeBottom, .resizeBottomLeft, .resizeBottomRight].contains(self)
    }

    var isLeft: Bool {
        return [.resizeLeft, .resizeTopLeft, .resizeBottomLeft].contains(self)
    }

    var isTop: Bool {
        return [.resizeTop, .resizeTopLeft, .resizeTopRight].contains(self)
    }
}

protocol LayoutPageComponentProvider {
    func component(at point: CGPoint, in page: LayoutEnginePage) -> LayoutEnginePageComponent?
}

class LayoutEnginePage: Equatable {
    let id: UUID
    var componentProvider: LayoutPageComponentProvider?
    var canvasOrigin: CGPoint = .zero
    var pageOrigin: CGPoint
    var size: CGSize
    var selected: Bool = false
    var minSize: CGSize = .zero

    var pageFrame: CGRect {
        return CGRect(origin: self.pageOrigin, size: self.size)
    }

    var canvasFrame: CGRect {
        return CGRect(origin: self.canvasOrigin, size: self.size)
    }

    weak var layoutEngine: CanvasLayoutEngine?
    init(id: UUID, pageOrigin: CGPoint, size: CGSize, componentProvider: LayoutPageComponentProvider? = nil) {
        self.id = id
        self.componentProvider = componentProvider
        self.pageOrigin = pageOrigin
        self.size = size
    }

    func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        return self.componentProvider?.component(at: point, in: self)
    }

    static func == (lhs: LayoutEnginePage, rhs: LayoutEnginePage) -> Bool {
        return lhs.id == rhs.id
    }
}
