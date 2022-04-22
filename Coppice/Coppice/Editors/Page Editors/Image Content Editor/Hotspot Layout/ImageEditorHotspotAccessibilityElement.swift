//
//  ImageEditorHotspotAccessibilityElement.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/04/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Foundation
import AppKit
import CoppiceCore

class ImageEditorHotspotAccessibilityElement: NSAccessibilityElement {
    let hotspot: ImageEditorHotspot
    weak var hotspotView: NSView?
    let modelController: CoppiceModelController
    init(hotspot: ImageEditorHotspot, hotspotView: NSView, modelController: CoppiceModelController) {
        self.hotspot = hotspot
        self.hotspotView = hotspotView
        self.modelController = modelController
        super.init()
        self.setAccessibilityRole(.link)
        let frame = NSAccessibility.screenRect(fromView: hotspotView, rect: hotspot.hotspotPath(forScale: 1).bounds)
        self.setAccessibilityFrame(frame)

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
}
