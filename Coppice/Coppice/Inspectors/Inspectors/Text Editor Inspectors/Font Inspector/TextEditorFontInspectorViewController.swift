//
//  TextEditorInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import ObjectiveC
import CoppiceCore

class TextEditorFontInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "TextEditorFontInspectorContentView"
    }

    override var ranking: InspectorRanking { return .content }

    @IBOutlet weak var colourPicker: TextColourPicker!
    @IBOutlet weak var styleControl: NSSegmentedControl!
    @IBOutlet weak var showFontPanelButton: NSButton!
    
    var typedViewModel: TextEditorFontInspectorViewModel {
        return self.viewModel as! TextEditorFontInspectorViewModel
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupStyleControl()
        self.setupColourPicker()

        let children = self.view.accessibilityChildren()?.compactMap { $0 as? NSAccessibilityElementProtocol }
        self.view.setAccessibilityChildrenInNavigationOrder(children)
        
        self.showFontPanelButton.image = NSImage.symbol(withName: Symbols.Text.textFormat)
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
        
        styleControl?.setImage(NSImage.symbol(withName: Symbols.Text.bold), forSegment: 0)
        styleControl?.setImage(NSImage.symbol(withName: Symbols.Text.italic), forSegment: 1)
        styleControl?.setImage(NSImage.symbol(withName: Symbols.Text.underline), forSegment: 2)
        styleControl?.setImage(NSImage.symbol(withName: Symbols.Text.strikethrough), forSegment: 3)
    }

    @IBAction func styleControlClicked(_ sender: Any) {
        self.updateStyle(forSegment: 0, keyPath: \.isBold)
        self.updateStyle(forSegment: 1, keyPath: \.isItalic)
        self.updateStyle(forSegment: 2, keyPath: \.isUnderlined)
        self.updateStyle(forSegment: 3, keyPath: \.isStruckthrough)
    }

    private func updateStyle(forSegment segment: Int, keyPath: ReferenceWritableKeyPath<TextEditorFontInspectorViewModel, Bool>) {
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
