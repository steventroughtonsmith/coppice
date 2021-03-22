//
//  NSImage+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSImage {
    public func pngData() -> Data? {
        guard let data = self.tiffRepresentation else {
            return nil
        }
        let rep = NSBitmapImageRep(data: data)
        return rep?.representation(using: .png, properties: [.compressionMethod: NSBitmapImageRep.TIFFCompression.none])
    }

    public func jpegData() -> Data? {
        guard let data = self.tiffRepresentation else {
            return nil
        }
        let rep = NSBitmapImageRep(data: data)
        return rep?.representation(using: .jpeg, properties: [
            .compressionMethod: NSBitmapImageRep.TIFFCompression.jpeg,
            .compressionFactor: 0.8,
        ])
    }

    public static func symbol(withName symbolName: String, accessibilityDescription: String? = nil) -> NSImage? {
        if #available(OSX 10.16, *) {
            if let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription) {
                return symbol
            }
        }
        let image = NSImage(named: symbolName)
        if let description = accessibilityDescription {
            image?.accessibilityDescription = description
        }
        return image
    }
}
