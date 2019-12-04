//
//  FileDropView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 04/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

@objc protocol FileDropViewDelegate: class {
    func validateDrop(forFileURL url: URL) -> Bool
    func acceptDrop(forFileURL url: URL) -> Bool
}


class FileDropView: NSView {
    @IBOutlet weak var delegate: FileDropViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.sharedSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.sharedSetup()
    }

    private func sharedSetup() {
        self.registerForDraggedTypes([.fileURL])
    }

    //MARK: - Dragging before image has gone
    private var isValidDrop = false

    private func validateDrop(with info: NSDraggingInfo) {
        guard let url = self.url(from: info.draggingPasteboard) else {
            self.isValidDrop = false
            return
        }

        self.isValidDrop = self.delegate?.validateDrop(forFileURL: url) ?? false
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.validateDrop(with: sender)
        guard self.isValidDrop else {
            return []
        }
        self.drawDropHighlight = true
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return self.isValidDrop ? .copy : []
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.drawDropHighlight = false
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.drawDropHighlight = false
    }


    //MARK: - Dragging after image has gone
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return self.isValidDrop
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = self.url(from: sender.draggingPasteboard) else {
            return false
        }

        return self.delegate?.acceptDrop(forFileURL: url) ?? false
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        self.isValidDrop = false
        self.drawDropHighlight = false
    }



    private func url(from pasteboard: NSPasteboard) -> URL? {
        guard let types = pasteboard.types, types.contains(.fileURL) else {
            return nil
        }

        guard let items = pasteboard.pasteboardItems, items.count == 1 else {
            return nil
        }

        guard let urlData = items.first!.data(forType: .fileURL) else {
            return nil
        }

        return URL(dataRepresentation: urlData, relativeTo: nil)
    }

    private var drawDropHighlight = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard self.drawDropHighlight else {
            return
        }
        //There doesn't seem to be a pre-defined colour for this so we'll approximate it as best we can
        NSColor.controlAccentColor.highlight(withLevel: 0.53)?.withAlphaComponent(0.55).set()
        let path = NSBezierPath(rect: self.bounds.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()
    }
}
