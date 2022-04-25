//
//  CroppedImageCache.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 25/04/2022.
//

import AppKit

public class CroppedImageCache {
    private var cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.name = "CroppedImageCache"
        return cache
    }()

    private var croppingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "com.mcubedsw.CroppingQueue"
        return queue
    }()

    public func croppedImage(for imageContent: ImagePageContent, completion: ((NSImage?) -> Void)? = nil) {
        guard let page = imageContent.page, let image = imageContent.image else {
            completion?(imageContent.image)
            return
        }

        guard imageContent.cropRect.size != image.size else {
            completion?(imageContent.image)
            return
        }

        let cropRect = imageContent.cropRect
        let cropKey = "\(page.id.stringRepresentation)_\(Int(cropRect.minX))_\(Int(cropRect.minY))_\(Int(cropRect.width))x\(Int(cropRect.height)))" as NSString

        if let cachedImage = self.cache.object(forKey: cropKey) {
            completion?(cachedImage)
            return
        }

        self.croppingQueue.addOperation {
            if let cachedImage = self.cache.object(forKey: cropKey) {
                OperationQueue.main.addOperation {
                    completion?(cachedImage)
                }
                return
            }

            let croppedImage = NSImage(size: cropRect.size)
            croppedImage.lockFocus()
            //TODO: iOS don't flip the image
            image.draw(in: CGRect(origin: .zero, size: cropRect.size), from: cropRect.flipped(in: CGRect(origin: .zero, size: image.size)), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            croppedImage.unlockFocus()

            self.cache.setObject(croppedImage, forKey: cropKey, cost: Int(croppedImage.size.width * croppedImage.size.height))
            OperationQueue.main.addOperation {
                completion?(croppedImage)
            }
        }
    }
}
