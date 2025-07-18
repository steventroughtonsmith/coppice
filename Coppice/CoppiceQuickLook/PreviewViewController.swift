//
//  PreviewViewController.swift
//  CoppiceQuickLook
//
//  Created by Martin Pilkington on 20/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {
    @IBOutlet weak var canvasImageView: NSImageView!

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.

        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */

    let previewGenerator = QuickLookPreviewGenerator()

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            guard let image = try self.previewGenerator.previewImage(for: url) else {
                handler(nil)
                return
            }

            self.canvasImageView.image = image
        } catch {
            handler(error)
            return
        }
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

        // Perform any setup necessary in order to prepare the view.

        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.

        handler(nil)
    }
}
