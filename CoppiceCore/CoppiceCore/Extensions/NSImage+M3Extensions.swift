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

	public enum RotationDirection {
		case left
		case right

		var radians: CGFloat {
			switch self {
			case .left:
				return Double.pi / 2
			case .right:
				return -Double.pi / 2
			}
		}
	}

	public func rotate90Degrees(_ direction: RotationDirection) -> NSImage? {
		guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
			return nil
		}

		let ciImage = CIImage(cgImage: cgImage)
		let rotatedCIImage = ciImage.transformed(by: CGAffineTransform(rotationAngle: direction.radians))

		guard let rotatedCGImage = CIContext().createCGImage(rotatedCIImage, from: rotatedCIImage.extent) else {
			return nil
		}

		let rotatedSize = CGSize(width: self.size.height, height: self.size.width)
		let bitmapRep = NSBitmapImageRep(cgImage: rotatedCGImage)
		bitmapRep.size = rotatedSize
		let finalImage = NSImage(size: rotatedSize)
		finalImage.addRepresentation(bitmapRep)
		return finalImage
	}
}
