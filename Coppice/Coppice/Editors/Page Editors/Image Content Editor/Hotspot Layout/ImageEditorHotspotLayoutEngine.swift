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
            self.hotspots.forEach {
                $0.layoutEngine = self
                $0.originOffset = self.cropRect.origin
            }
            self.delegate?.layoutDidChange(in: self)
        }
    }

    var visibleHotspots: [ImageEditorHotspot] {
        //We want the cropped rect set to a zero origin, this is because the hotspot path will be adjusted
        let visibleRect = self.cropRect.size.toRect()
        return self.hotspots.filter { visibleRect.contains($0.hotspotPath(forScale: 1).bounds) }
    }

    var imageSize: CGSize = .zero
    var cropRect: CGRect = .zero {
        didSet {
            self.hotspots.forEach { $0.originOffset = self.cropRect.origin }
        }
    }

    var hotspotKindForCreation: ImageHotspot.Kind = .rectangle

    var isEditable = true

    private(set) var hoveredHotspot: ImageEditorHotspot? {
        didSet {
            if self.hoveredHotspot === oldValue {
                return
            }
            oldValue?.isHovered = false
            self.hoveredHotspot?.isHovered = true
            self.delegate?.layoutDidChange(in: self)
        }
    }

    var highlightedPageLink: PageLink? {
        didSet {
            guard oldValue != self.highlightedPageLink else {
                return
            }

            guard let pageLink = self.highlightedPageLink else {
                self.hotspots.forEach { $0.isHighlighted = false }
                self.delegate?.layoutDidChange(in: self)
                return
            }

            for hotspot in self.hotspots {
                guard
                    let url = hotspot.url,
                    let pageLink = PageLink(url: url)
                else {
                    hotspot.isHighlighted = false
                    continue
                }

                hotspot.isHighlighted = (pageLink.destination == self.highlightedPageLink?.destination)
            }
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

    func hotspot(at point: CGPoint) -> ImageEditorHotspot? {
        return self.hotspots.last(where: { $0.hitTest(at: point) })
    }

    private var hotspotBeingCreated: ImageEditorHotspot? {
        return self.hotspots.first(where: { $0.mode == .creating })
    }

    private var currentHotspotForEvents: ImageEditorHotspot?
    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        let hotspotForEvent: ImageEditorHotspot
        if let hotspot = self.hotspots.last(where: { $0.hitTest(at: point) }) {
            hotspotForEvent = hotspot
        } else if self.isEditable {
            if let hotspotBeingCreated = self.hotspotBeingCreated {
                hotspotForEvent = hotspotBeingCreated
            } else {
                switch self.hotspotKindForCreation {
                case .rectangle:
                    hotspotForEvent = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(origin: point, size: .zero), url: nil, mode: .creating, imageSize: self.imageSize)
                case .oval:
                    hotspotForEvent = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(origin: point, size: .zero), url: nil, mode: .creating, imageSize: self.imageSize)
                case .polygon:
                    hotspotForEvent = ImageEditorPolygonHotspot(points: [point], mode: .creating, imageSize: self.imageSize)
                }
                self.hotspots.append(hotspotForEvent)
            }
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
        let isCreating = (currentHotspotForEvents.mode == .creating)
        self.currentHotspotForEvents = nil

        self.delegate?.layoutDidChange(in: self)
        if self.isEditable, hasChanged, isCreating == false {
            self.delegate?.didCommitEdit(in: self)
        } else if modifiers.contains(.option) == false {
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
            self.hoveredHotspot = nil
            return
        }

        self.hoveredHotspot = hotspot
    }

    func handleKeyDown(with keyCode: UInt16, modifiers: LayoutEventModifiers) -> Bool {
        return keyCode == UInt16(kVK_Delete)
    }

    func handleKeyUp(with keyCode: UInt16, modifiers: LayoutEventModifiers) -> Bool {
        if keyCode == UInt16(kVK_Delete) {
            self.hotspots = self.hotspots.filter { $0.isSelected == false }
            self.delegate?.layoutDidChange(in: self)
            self.delegate?.didCommitEdit(in: self)
            return true
        }
        return false
    }

    //MARK: - Accessibility
    func accessibilityMoveHandle(atIndex index: Int, of hotspot: ImageEditorHotspot, byDelta delta: CGPoint) -> CGPoint {
        let delta = hotspot.accessibilityMoveHandle(atIndex: index, byDelta: delta)
        self.delegate?.layoutDidChange(in: self)
        return delta
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
    var isHovered: Bool { get set }
    var isHighlighted: Bool { get set }
    var isClicked: Bool { get }
    var mode: ImageEditorHotspotMode { get }
    var originOffset: CGPoint { get set }

    //MARK: - Data
    var imageHotspot: ImageHotspot? { get }
    var layoutEngine: ImageEditorHotspotLayoutEngine? { get set }

    //MARK: - Event Handling
    func hitTest(at point: CGPoint) -> Bool

    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int)
    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) -> Bool
    func movedEvent(at point: CGPoint)

    //MARK: - Accessibility
    func accessibilityMoveHandle(atIndex index: Int, byDelta delta: CGPoint) -> CGPoint
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
