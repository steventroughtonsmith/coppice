//
//  ImagePageLinkManager.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/04/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa
import Vision

import CoppiceCore
import M3Data

class ImagePageLinkManager: PageLinkManager {
    private var observer: ModelCollection<Page>.Observation!

    override init(pageID: ModelID, modelController: ModelController) {
        super.init(pageID: pageID, modelController: modelController)

        self.observer = self.modelController.collection(for: Page.self).addObserver { [weak self] change in
            //Rescan the image for text if its content was updated
            if change.object.id == self?.pageID && change.didUpdate(\.content) {
                self?.setNeedsRescan()
                return
            }

            //Update the hotspots if a page was added, deleted, or had its titled or allowsAutoLinking changed
            guard change.changeType != .update || change.didUpdate(\.title) || change.didUpdate(\.allowsAutoLinking) else {
                return
            }

            self?.setNeedsHotspotGeneration()
        }
    }

    deinit {
        if let observer = self.observer {
            self.modelController.collection(for: Page.self).removeObserver(observer)
        }
    }

    func setNeedsRescan() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.rescanImage), object: nil)
        self.perform(#selector(self.rescanImage), with: nil, afterDelay: 0)
    }

    @objc dynamic private func rescanImage() {
        guard
            let page = self.modelController.collection(for: Page.self).objectWithID(self.pageID),
            let imageContent = page.content as? ImagePageContent,
            let cgImage = imageContent.image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return
        }

        //Orientation is weird, look at ImagePageContent.orientation for more
        let imageRequestHandle = VNImageRequestHandler(cgImage: cgImage, orientation: imageContent.orientation)
        let detectionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            DispatchQueue.main.async {
                self.processResults(from: request)
            }
        })

        do {
            if #available(macOS 12, *) {
                detectionRequest.recognitionLanguages = try detectionRequest.supportedRecognitionLanguages()
            } else if #available(macOS 11, *) {
                detectionRequest.recognitionLanguages = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision2)
            } else {
                detectionRequest.recognitionLanguages = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision1)
            }
        } catch {
            //Guess we're not recognising other languages today
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandle.perform([detectionRequest])
            } catch {
                print("Error performing image request: \(error)")
            }
        }
    }

    private func processResults(from request: VNRequest) {
        guard
            let page = self.modelController.collection(for: Page.self).objectWithID(self.pageID),
            let imageContent = page.content as? ImagePageContent,
            let results = request.results as? [VNRecognizedTextObservation]
        else {
            return
        }

        imageContent.recognizedTexts = results.compactMap { result in
            guard let recognisedText = result.topCandidates(1).first else {
                return nil
            }

            let cleanString = recognisedText.string.components(separatedBy: .punctuationCharacters.union(.whitespaces)).joined(separator: "")
            //If we have high confidence, we'll let you only be two characters
            if recognisedText.confidence >= 0.9 {
                guard cleanString.count >= 2 else {
                    return nil
                }
                //If we have medium confidence, we'll need you to be at least 4 characters
            } else if recognisedText.confidence >= 0.5 {
                guard cleanString.count >= 4 else {
                    return nil
                }
                //Otherwise go away
            } else {
                return nil
            }
            return recognisedText
        }
        self.setNeedsHotspotGeneration()
    }

    //MARK: - Hotspot Generation
    private func setNeedsHotspotGeneration() {
        guard
            UserDefaults.standard.bool(forKey: .autoLinkingTextPagesEnabled),
            self.isProEnabled
        else {
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.regenerateHotspots), object: nil)
        self.perform(#selector(self.regenerateHotspots), with: nil, afterDelay: 0)
    }

    @objc dynamic private func regenerateHotspots() {
        guard
            let page = self.modelController.collection(for: Page.self).objectWithID(self.pageID),
            let imageContent = page.content as? ImagePageContent,
            let image = imageContent.image
        else {
            return
        }

        let pages = Array(self.modelController.collection(for: Page.self).all)
        var ignoredPage: [Page] = [page]
        ignoredPage.append(contentsOf: pages.filter { $0.allowsAutoLinking == false })

        imageContent.hotspots = ImageLinkFinder.updateHotspots(imageContent.hotspots,
                                                               for: imageContent.recognizedTexts,
                                                               using: pages,
                                                               ignoring: ignoredPage,
                                                               imageSize: image.size,
                                                               orientation: imageContent.orientation)
    }
}


