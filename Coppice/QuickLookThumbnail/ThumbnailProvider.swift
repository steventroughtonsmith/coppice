//
//  ThumbnailProvider.swift
//  QuickLookThumbnail
//
//  Created by Martin Pilkington on 19/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore
import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let previewGenerator = QuickLookPreviewGenerator()
        let image: NSImage?
        do {
            image = try previewGenerator.previewImage(for: request.fileURL)
        } catch {
            handler(nil, error)
            return
        }

        let imageDrawSize = image?.size.scaleDownToFit(request.maximumSize) ?? request.maximumSize
        handler(QLThumbnailReply(contextSize: imageDrawSize, currentContextDrawing: { () -> Bool in
            guard let image else {
                return false
            }

            let drawRect = CGRect(origin: .zero, size: imageDrawSize.rounded())
            image.draw(in: drawRect,
                       from: CGRect(origin: .zero, size: image.size),
                       operation: .sourceOver,
                       fraction: 1)
            return true
        }), nil)
    }
}
