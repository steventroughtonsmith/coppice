//
//  ImageEditorHotspotLayoutEngine.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/02/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import Carbon.HIToolbox
import Foundation

import CoppiceCore

protocol ImageEditorHotspotLayoutEngineDelegate: AnyObject {
    func layoutDidChange(in layoutEngine: ImageEditorHotspotLayoutEngine)
    func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine)
}

class ImageEditorHotspotLayoutEngine {
    weak var delegate: ImageEditorHotspotLayoutEngineDelegate?

    var hotspots: [ImageEditorHotspot] = [] //Ordered last to first = front to back
    private(set) var highlightedHotspot: ImageEditorHotspot?
    func selectAll() {
        self.hotspots.forEach { $0.isSelected = true }
        self.delegate?.layoutDidChange(in: self)
    }

    func deselectAll() {
        self.hotspots.forEach { $0.isSelected = false }
        self.delegate?.layoutDidChange(in: self)
    }

    private var currentHotspotForEvents: ImageEditorHotspot?
    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        guard let hotspot = hotspots.last(where: { $0.hitTest(at: point) }) else {
            //MARK: - Handle creation
            return
        }

        currentHotspotForEvents = hotspot
        hotspot.downEvent(at: point, modifiers: modifiers, eventCount: eventCount)
    }

    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.currentHotspotForEvents?.draggedEvent(at: point, modifiers: modifiers, eventCount: eventCount)

        self.delegate?.layoutDidChange(in: self)
    }

    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.currentHotspotForEvents?.upEvent(at: point, modifiers: modifiers, eventCount: eventCount)
        self.currentHotspotForEvents = nil

        self.delegate?.layoutDidChange(in: self)
    }

    func flagsChanged(at point: CGPoint, modifiers: LayoutEventModifiers) {
        guard let currentHotspotForEvents = self.currentHotspotForEvents else {
            return
        }

        currentHotspotForEvents.draggedEvent(at: point, modifiers: modifiers, eventCount: 1)

        self.delegate?.layoutDidChange(in: self)
    }

    func movedEvent(at point: CGPoint) {

    }

    func keyUpEvent(with keyCode: UInt16, modifiers: LayoutEventModifiers) {
        if keyCode == UInt16(kVK_Delete) {
            self.hotspots = self.hotspots.filter { $0.isSelected == false }
            self.delegate?.layoutDidChange(in: self)
            self.delegate?.didCommitEdit(in: self)
        }
    }
}

enum ImageEditorHotspotMode {
    case view
    case create
    case edit
}

protocol ImageEditorHotspot: AnyObject {
    var resizeHandleSize: CGFloat { get }

    //MARK: - Drawing/Interaction
    func hotspotPath(forScale scale: CGFloat) -> NSBezierPath
    func editingBoundsPaths(forScale scale: CGFloat) -> [(path: NSBezierPath, phase: CGFloat)]
    func editingHandleRects(forScale scale: CGFloat) -> [CGRect]

    //MARK: - State
    var isSelected: Bool { get set }
    var mode: ImageEditorHotspotMode { get }

    //MARK: - Data
    var imageHotspot: ImageHotspot? { get }
    var layoutEngine: ImageEditorHotspotLayoutEngine? { get set }

    //MARK: - Event Handling
    func hitTest(at point: CGPoint) -> Bool

    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func movedEvent(at point: CGPoint)
}

extension ImageEditorHotspot {
    var resizeHandleSize: CGFloat {
        return 10
    }
}

//class ImageEditorPolygonHotspot: ImageEditorHotspot {
//    private var isComplete: Bool
//    init(points: [CGPoint], url: URL? = nil, isNewHotspot: Bool = false) {
//
//    }
//}
