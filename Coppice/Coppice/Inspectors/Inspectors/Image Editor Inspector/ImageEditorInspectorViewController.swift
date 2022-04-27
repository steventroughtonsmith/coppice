//
//  ImageEditorInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "ImageEditorInspectorContentView"
    }

    override var ranking: InspectorRanking { return .content }
    @IBOutlet var descriptionScrollViewHeight: NSLayoutConstraint!
    @IBOutlet var descriptionTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTextViewHeight()
    }

	private var typedViewModel: ImageEditorInspectorViewModel {
		return self.viewModel as! ImageEditorInspectorViewModel
	}

    private func updateTextViewHeight() {
        guard
            let layoutManager = self.descriptionTextView.layoutManager,
            let textContainer = self.descriptionTextView.textContainer
        else {
            return
        }

        //We need to add 1pt at the top and bottom to account for the border
        let height = layoutManager.usedRect(for: textContainer).height + 2

        self.descriptionScrollViewHeight.constant = max(60, min(height, 150))
    }

    @IBAction func rotate(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.typedViewModel.rotateLeft()
        } else {
            self.typedViewModel.rotateRight()
        }
    }
}

extension ImageEditorInspectorViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        self.updateTextViewHeight()
    }
}
