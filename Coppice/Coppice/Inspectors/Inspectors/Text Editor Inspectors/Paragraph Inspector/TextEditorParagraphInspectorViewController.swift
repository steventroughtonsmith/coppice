//
//  TextEditorParagraphInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/12/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class TextEditorParagraphInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "TextEditorParagraphInspectorView"
    }

    override var ranking: InspectorRanking { return .content }

    @IBOutlet weak var alignmentControl: NSSegmentedControl!

    var typedViewModel: TextEditorParagraphInspectorViewModel {
        return self.viewModel as! TextEditorParagraphInspectorViewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAlignmentControl()
    }

    //MARK: - Alignment Control
    private var alignmentObserver: AnyCancellable!
    private func setupAlignmentControl() {
        guard let alignmentControl = self.alignmentControl else {
            return
        }
        alignmentControl.setTag(NSTextAlignment.left.rawValue, forSegment: 0)
        alignmentControl.setTag(NSTextAlignment.center.rawValue, forSegment: 1)
        alignmentControl.setTag(NSTextAlignment.right.rawValue, forSegment: 2)
        alignmentControl.setTag(NSTextAlignment.justified.rawValue, forSegment: 3)

        self.alignmentObserver = self.typedViewModel.publisher(for: \.rawAlignment)
            .map {alignmentControl.segment(forTag: $0) }
            .assign(to: \.selectedSegment, on: alignmentControl)
    }

    @IBAction func alignmentClicked(_ sender: Any) {
        self.typedViewModel.rawAlignment = self.alignmentControl.selectedTag()
    }
}


extension TextEditorParagraphInspectorViewController: TextEditorParagraphInspectorView {
}
