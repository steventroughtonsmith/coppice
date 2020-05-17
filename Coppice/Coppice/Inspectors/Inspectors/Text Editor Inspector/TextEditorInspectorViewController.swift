//
//  TextEditorInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class TextEditorInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "TextEditorInspectorContentView"
    }

    override var ranking: InspectorRanking { return .content }

    @IBOutlet weak var colourPicker: TextColourPicker!
    @IBOutlet weak var alignmentControl: NSSegmentedControl!
    @IBOutlet weak var styleControl: NSSegmentedControl!

    var typedViewModel: TextEditorInspectorViewModel {
        return self.viewModel as! TextEditorInspectorViewModel
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAlignmentControl()
        self.setupStyleControl()
        self.setupColourPicker()

        let children = self.view.accessibilityChildren()?.compactMap { $0 as? NSAccessibilityElementProtocol }
        self.view.setAccessibilityChildrenInNavigationOrder(children)
    }


    //MARK: - Colour Control
    private var textColourObserver: AnyCancellable!
    private func setupColourPicker() {
        guard let colourPicker = self.colourPicker else {
            return
        }

        self.textColourObserver = self.typedViewModel.publisher(for: \.textColour)
            .map { $0 ?? .clear }
            .assign(to: \.colour, on: colourPicker)
    }

    @IBAction func colourChanged(_ sender: Any) {
        self.typedViewModel.textColour = self.colourPicker.colour
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

        self.alignmentObserver = self.typedViewModel.publisher(for: \.rawAlignment)
                                                    .map {alignmentControl.segment(forTag: $0) }
                                                    .assign(to: \.selectedSegment, on: alignmentControl)
    }

    @IBAction func alignmentClicked(_ sender: Any) {
        self.typedViewModel.rawAlignment = self.alignmentControl.selectedTag()
    }


    //MARK: - Style Control
    private var boldObserver: AnyCancellable!
    private var italicObserver: AnyCancellable!
    private var underlineObserver: AnyCancellable!
    private var strikethroughObserver: AnyCancellable!
    private func setupStyleControl() {
        let styleControl = self.styleControl
        self.boldObserver = self.typedViewModel.publisher(for: \.isBold)
                                               .sink { styleControl?.setSelected($0, forSegment: 0) }
        self.italicObserver = self.typedViewModel.publisher(for: \.isItalic)
                                                 .sink { styleControl?.setSelected($0, forSegment: 1) }
        self.underlineObserver = self.typedViewModel.publisher(for: \.isUnderlined)
                                                    .sink { styleControl?.setSelected($0, forSegment: 2) }
        self.strikethroughObserver = self.typedViewModel.publisher(for: \.isStruckthrough)
                                                        .sink { styleControl?.setSelected($0, forSegment: 3) }
    }

    @IBAction func styleControlClicked(_ sender: Any) {
        self.updateStyle(forSegment: 0, keyPath: \.isBold)
        self.updateStyle(forSegment: 1, keyPath: \.isItalic)
        self.updateStyle(forSegment: 2, keyPath: \.isUnderlined)
        self.updateStyle(forSegment: 3, keyPath: \.isStruckthrough)
    }

    private func updateStyle(forSegment segment: Int, keyPath: ReferenceWritableKeyPath<TextEditorInspectorViewModel, Bool>) {
        let selected = self.styleControl.isSelected(forSegment: segment)
        guard (selected != self.typedViewModel[keyPath: keyPath]) else {
            return
        }
        self.typedViewModel[keyPath: keyPath] = selected
    }

    @IBAction func showFontPanel(_ sender: Any?) {
        NSFontManager.shared.orderFrontFontPanel(sender)
    }
}
