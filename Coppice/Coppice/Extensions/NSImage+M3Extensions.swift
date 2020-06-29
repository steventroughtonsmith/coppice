//
//  NSImage+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSImage {
    func pngData() -> Data? {
        guard let data = self.tiffRepresentation else {
            return nil
        }
        let rep = NSBitmapImageRep(data: data)
        return rep?.representation(using: .png, properties: [.compressionMethod: NSBitmapImageRep.TIFFCompression.none])
    }

    static func symbol(withName symbolName: String, accessibilityDescription: String? = nil) -> NSImage? {
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
