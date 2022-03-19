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
    func didClickOnHotspot(_ hotspot: ImageEditorHotspot, in layoutEngine: ImageEditorHotspotLayoutEngine)
}

extension ImageEditorHotspotLayoutEngineDelegate {
    func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine) {}
    func didClickOnHotspot(_ hotspot: ImageEditorHotspot, in layoutEngine: ImageEditorHotspotLayoutEngine) {}
}

class ImageEditorHotspotLayoutEngine {
    weak var delegate: ImageEditorHotspotLayoutEngineDelegate?

    var hotspots: [ImageEditorHotspot] = [] {  //Ordered last to first = front to back
        didSet {
            self.hotspots.forEach { $0.layoutEngine = self }
            self.delegate?.layoutDidChange(in: self)
        }
    }

    var imageSize: CGSize = .zero

    var hotspotKindForCreation: ImageHotspot.Kind = .rectangle

    var isEditable = true

    private(set) var highlightedHotspot: ImageEditorHotspot? {
        didSet {
            if self.highlightedHotspot === oldValue {
                return
            }
            oldValue?.isHighlighted = false
            self.highlightedHotspot?.isHighlighted = true
            self.delegate?.layoutDidChange(in: self)
        }
    }

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
        let hotspotForEvent: ImageEditorHotspot
        if let hotspot = hotspots.last(where: { $0.hitTest(at: point) }) {
            hotspotForEvent = hotspot
        } else if self.isEditable {
            if self.hotspotKindForCreation == .oval {
                hotspotForEvent = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(origin: point, size: .zero), url: nil, mode: .creating, imageSize: self.imageSize)
            } else {
                hotspotForEvent = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(origin: point, size: .zero), url: nil, mode: .creating, imageSize: self.imageSize)
            }
            self.hotspots.append(hotspotForEvent)
        } else {
            return
        }

        self.currentHotspotForEvents = hotspotForEvent
        hotspotForEvent.downEvent(at: point, modifiers: modifiers, eventCount: eventCount)
        self.delegate?.layoutDidChange(in: self)
    }

    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.currentHotspotForEvents?.draggedEvent(at: point, modifiers: modifiers, eventCount: eventCount)

        self.delegate?.layoutDidChange(in: self)
    }

    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        guard let currentHotspotForEvents = self.currentHotspotForEvents else {
            return
        }

        let hasChanged = currentHotspotForEvents.upEvent(at: point, modifiers: modifiers, eventCount: eventCount)
        self.currentHotspotForEvents = nil

        self.delegate?.layoutDidChange(in: self)
        if self.isEditable, hasChanged {
            self.delegate?.didCommitEdit(in: self)
        } else {
            self.delegate?.didClickOnHotspot(currentHotspotForEvents, in: self)
        }
    }

    func flagsChanged(at point: CGPoint, modifiers: LayoutEventModifiers) {
        guard let currentHotspotForEvents = self.currentHotspotForEvents else {
            return
        }

        currentHotspotForEvents.draggedEvent(at: point, modifiers: modifiers, eventCount: 1)

        self.delegate?.layoutDidChange(in: self)
    }

    func movedEvent(at point: CGPoint) {
        guard
            self.isEditable == false,
            let hotspot = hotspots.last(where: { $0.hitTest(at: point) })
        else {
            self.highlightedHotspot = nil
            return
        }

        self.highlightedHotspot = hotspot
    }

    func performKeyEquivalent(with keyCode: UInt16, modifiers: LayoutEventModifiers) -> Bool {
        if keyCode == UInt16(kVK_Delete) {
            self.hotspots = self.hotspots.filter { $0.isSelected == false }
            self.delegate?.layoutDidChange(in: self)
            self.delegate?.didCommitEdit(in: self)
            return true
        }
        return false
    }


}

enum ImageEditorHotspotMode {
    case creating
    case complete
}

protocol ImageEditorHotspot: AnyObject {
    var resizeHandleSize: CGFloat { get }

    var url: URL? { get set }

    //MARK: - Drawing/Interaction
    func hotspotPath(forScale scale: CGFloat) -> NSBezierPath
    func editingBoundsPaths(forScale scale: CGFloat) -> [(path: NSBezierPath, phase: CGFloat)]
    func editingHandleRects(forScale scale: CGFloat) -> [CGRect]

    //MARK: - State
    var isSelected: Bool { get set }
    var isHighlighted: Bool { get set }
    var isClicked: Bool { get }
    var mode: ImageEditorHotspotMode { get }

    //MARK: - Data
    var imageHotspot: ImageHotspot? { get }
    var layoutEngine: ImageEditorHotspotLayoutEngine? { get set }

    //MARK: - Event Handling
    func hitTest(at point: CGPoint) -> Bool

    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) -> Bool
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
