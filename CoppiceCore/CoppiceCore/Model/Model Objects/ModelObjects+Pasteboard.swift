//
//  ModelObjects+Pasteboard.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

public extension Canvas {
    var pasteboardWriter: NSPasteboardWriting {
        return self.id.pasteboardItem
    }
}

public extension Page {
    var pasteboardWriter: NSPasteboardWriting {
        let filePromiseProvider = self.content.filePromiseProvider
        filePromiseProvider.additionalItems[ModelID.PasteboardType] = self.id.plistRepresentation
        return filePromiseProvider
    }
}

public extension Folder {
    var pasteboardWriter: NSPasteboardWriting {
        return self.id.pasteboardItem
    }
}

extension TextPageContent: NSFilePromiseProviderDelegate {
    public var filePromiseProvider: ExtendableFilePromiseProvider {
        return ExtendableFilePromiseProvider(fileType: (kUTTypeRTF as String), delegate: self)
    }

    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        guard let page = self.page, fileType == (kUTTypeRTF as String) else {
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
        } catch let error {
            completionHandler(error)
        }
    }
}

extension ImagePageContent: NSFilePromiseProviderDelegate {
    public var filePromiseProvider: ExtendableFilePromiseProvider {
        return ExtendableFilePromiseProvider(fileType: (kUTTypePNG as String), delegate: self)
    }

    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        guard let page = self.page, fileType == (kUTTypePNG as String) else {
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
        } catch let error {
            completionHandler(error)
        }
    }
}


public class ExtendableFilePromiseProvider: NSFilePromiseProvider {
    public var additionalItems: [NSPasteboard.PasteboardType: Any] = [:]

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
