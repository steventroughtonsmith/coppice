//
//  ImageEditorHotspotAccessibilityElement.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/04/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import Foundation

import CoppiceCore

class ImageEditorHotspotAccessibilityElement: NSAccessibilityElement {
    let hotspot: ImageEditorHotspot
    weak var hotspotView: NSView?
    let modelController: CoppiceModelController
    let isEditable: Bool
    init(hotspot: ImageEditorHotspot, hotspotView: NSView, modelController: CoppiceModelController, isEditable: Bool) {
        self.hotspot = hotspot
        self.hotspotView = hotspotView
        self.modelController = modelController
        self.isEditable = isEditable
        super.init()

        self.setupRole()
        self.setupFrame()
        self.setupLabel()

        self.setupResizeHandles()
    }

    func refresh() {
        self.setupFrame()
        self.setupResizeHandles()
        self.setupLabel()
    }

    private func setupRole() {
        if self.isEditable {
            self.setAccessibilityRole(.group)
            self.setAccessibilityRoleDescription("Image Hotspot")
        } else {
            self.setAccessibilityRole(.link)
        }
    }

    private func setupFrame() {
        guard let hotspotView = self.hotspotView else {
            return
        }

        let frame = NSAccessibility.screenRect(fromView: hotspotView, rect: self.hotspot.hotspotPath(forScale: 1).bounds)
        self.setAccessibilityFrame(frame)
    }

    private func setupLabel() {
        if let url = hotspot.url {
            if let pageLink = PageLink(url: url) {
                if let page = modelController.pageCollection.objectWithID(pageLink.destination) {
                    self.setAccessibilityLabel(page.title)
                } else {
                    self.setAccessibilityLabel("Unknown Page")
                }
            } else {
                self.setAccessibilityLabel(url.absoluteString)
            }
        } else {
            self.setAccessibilityLabel("Empty")
        }
    }

    private var resizeHandles: [MovableHandleAccessibilityElement] = []

    private func setupResizeHandles() {
        guard
            self.isEditable,
            let hotspotView = self.hotspotView
        else {
            return
        }

        var handles = [MovableHandleAccessibilityElement]()
        for (index, handleRect) in self.hotspot.editingHandleRects(forScale: 1).enumerated() {
            let frame = NSAccessibility.screenRect(fromView: hotspotView, rect: handleRect)
            let handle = self.resizeHandle(atIndex: index)
            handle.setAccessibilityFrame(frame, callingDelegate: false)
            handles.append(handle)
        }

        self.resizeHandles = handles

        self.setAccessibilityChildren(handles)
        self.setAccessibilityChildrenInNavigationOrder(handles)
    }

    private func resizeHandle(atIndex index: Int) -> MovableHandleAccessibilityElement {
        if let existingHandle = self.resizeHandles[safe: index] {
            return existingHandle
        }
        let handle = MovableHandleAccessibilityElement.element(withRole: .handle, frame: .zero, label: "Hotspot Resize Handle \(index + 1)", parent: self) as! MovableHandleAccessibilityElement
        handle.delegate = self
        return handle
    }

    override func accessibilityPerformPress() -> Bool {
        self.hotspot.layoutEngine?.deselectAll()
        self.hotspot.isSelected = true
        return true
    }
}

extension ImageEditorHotspotAccessibilityElement: MovableHandleAccessibilityElementDelegate {
    func didMove(_ handle: MovableHandleAccessibilityElement, byDelta delta: CGPoint) -> CGPoint {
        guard let index = self.resizeHandles.firstIndex(of: handle) else {
            return .zero
        }
        return self.hotspot.layoutEngine?.accessibilityMoveHandle(atIndex: index, of: self.hotspot, byDelta: delta) ?? .zero
    }
}
