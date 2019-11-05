//
//  NSImage+M3Extensions.swift
//  Bubbles
//
//  Created by Martin Pilkington on 29/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSImage {
    func pngData() -> Data? {
        return self.bitmapRepresentation()?.representation(using: .png, properties: [:])
    }

    private func bitmapRepresentation() -> NSBitmapImageRep? {
        if let rep = self.representations.first(where: {$0 is NSBitmapImageRep}) {
            return (rep as! NSBitmapImageRep)
        }

        guard let data = self.tiffRepresentation else {
            return nil
        }
        return NSBitmapImageRep(data: data)
    }
}
