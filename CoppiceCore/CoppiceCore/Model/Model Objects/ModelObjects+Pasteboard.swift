//
//  ModelObjects+Pasteboard.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import M3Data
import UniformTypeIdentifiers

extension Canvas {
    public var pasteboardWriter: NSPasteboardWriting {
        return self.id.pasteboardItem
    }
}

extension Page {
    public var pasteboardWriter: NSPasteboardWriting {
        let filePromiseProvider = self.content.filePromiseProvider
        filePromiseProvider.additionalItems[ModelID.PasteboardType] = self.id.plistRepresentation
        return filePromiseProvider
    }
}

extension Folder {
    public var pasteboardWriter: NSPasteboardWriting {
        return self.id.pasteboardItem
    }
}

extension Page.Content.Text: NSFilePromiseProviderDelegate {
    public override var filePromiseProvider: ExtendableFilePromiseProvider {
        return ExtendableFilePromiseProvider(type: .rtf, delegate: self)
    }

    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        guard
            let page = self.page,
            let type = UTType(fileType),
            type == .rtf
        else {
            return ""
        }
        return page.title + ".rtf"
    }

    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let data = self.modelFile.data else {
            completionHandler(nil)
            return
        }
        do {
            try data.write(to: url)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}

extension Page.Content.Image: NSFilePromiseProviderDelegate {
    public override var filePromiseProvider: ExtendableFilePromiseProvider {
        return ExtendableFilePromiseProvider(type: .png, delegate: self)
    }

    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        guard
            let page = self.page,
            let type = UTType(fileType),
            type == .png
        else {
            return ""
        }
        return page.title + ".png"
    }

    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let data = self.modelFile.data else {
            completionHandler(nil)
            return
        }
        do {
            try data.write(to: url)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}


public class ExtendableFilePromiseProvider: NSFilePromiseProvider {
    public var additionalItems: [NSPasteboard.PasteboardType: Any] = [:]

    convenience init(type: UTType, delegate: NSFilePromiseProviderDelegate) {
        self.init(fileType: type.identifier, delegate: delegate)
    }

    public override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        if self.additionalItems.count > 0 {
            types.append(contentsOf: self.additionalItems.keys)
        }
        return types
    }

    public override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if let item = self.additionalItems[type] {
            return item
        }
        return super.pasteboardPropertyList(forType: type)
    }
}
