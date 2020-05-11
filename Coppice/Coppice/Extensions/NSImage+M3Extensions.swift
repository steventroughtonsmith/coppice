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
}
