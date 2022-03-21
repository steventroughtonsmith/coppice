//
//  ImageEditorPolygonHotspot.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class ImageEditorPolygonHotspot: ImageEditorHotspot {
    private(set) var points: [CGPoint]
    var url: URL? = nil
    private(set) var mode: ImageEditorHotspotMode
    let imageSize: CGSize
    init(points: [CGPoint], url: URL? = nil, mode: ImageEditorHotspotMode = .complete, imageSize: CGSize) {
        self.points = points
        self.url = url
        self.mode = mode
        self.imageSize = imageSize
    }

    //MARK: - Paths
    func hotspotPath(forScale scale: CGFloat) -> NSBezierPath {
        return NSBezierPath()
    }

    func editingBoundsPaths(forScale scale: CGFloat) -> [(path: NSBezierPath, phase: CGFloat)] {
        return []
    }

    //MARK: - Handle Rects
    func editingHandleRects(forScale scale: CGFloat) -> [CGRect] {
        return []
    }


    //MARK: - State
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    private(set) var isClicked: Bool = false

    var imageHotspot: ImageHotspot? {
        return nil
    }

    weak var layoutEngine: ImageEditorHotspotLayoutEngine?


	//MARK: - Hit Testing
    func hitTest(at point: CGPoint) -> Bool {
        return false
    }


    //MARK: - Events
    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        //Implement
    }

    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        //Implement
    }

    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) -> Bool {
        return false
    }

    func movedEvent(at point: CGPoint) {
        //Implement
    }
}
