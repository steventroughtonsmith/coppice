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
        self.setupListStylePopUpButton()
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


    //MARK: - List Style
    @IBOutlet var listStylePopUpButton: NSPopUpButton!
    private var listStylePopUpObserver: AnyCancellable!

    private enum SpecialListItemTags: Int {
        case none = -1
        case multiple = -2
        case customValue = -3
        case customise = -4
    }

    private func setupListStylePopUpButton() {
        self.listStylePopUpButton.removeAllItems()

        self.listStylePopUpButton.autoenablesItems = false
        self.listStylePopUpButton.addItem(withTitle: NSLocalizedString("Multiple", comment: "Multiple list style option name"))
        self.listStylePopUpButton.lastItem?.tag = SpecialListItemTags.multiple.rawValue
        self.listStylePopUpButton.lastItem?.isEnabled = false

        self.listStylePopUpButton.addItem(withTitle: NSLocalizedString("None", comment: "No list style option name"))
        self.listStylePopUpButton.lastItem?.tag = SpecialListItemTags.none.rawValue
        self.listStylePopUpButton.menu?.addItem(NSMenuItem.separator())

        let styles: [String] = [
            "{disc}", "{hyphen}", "{diamond}", "{check}",
            "{decimal}.",
            "{upper-latin}.", "{lower-latin}.",
            "{upper-roman}.", "{lower-roman}.",
        ]

        for style in styles {
            let textList = NSTextList(markerFormat: .init(rawValue:style), options: 0)
            self.listStylePopUpButton.addItem(withTitle: self.popUpTitle(for: textList))
            self.listStylePopUpButton.lastItem?.representedObject = style
        }

        self.listStylePopUpButton.menu?.addItem(NSMenuItem.separator())
        self.listStylePopUpButton.addItem(withTitle: "X Y Z")
        self.listStylePopUpButton.lastItem?.tag = SpecialListItemTags.customValue.rawValue
        self.listStylePopUpButton.addItem(withTitle: NSLocalizedString("Custom…", comment: "Custom list style option name"));
        self.listStylePopUpButton.lastItem?.tag = SpecialListItemTags.customise.rawValue

        self.listStylePopUpObserver = self.typedViewModel.publisher(for: \.listTypes).sink { [weak self] newValue in
            self?.updateListStylePopUpButton(with: newValue)
        }
    }

    private func popUpTitle(for textList: NSTextList) -> String {
        let firstItem = textList.marker(forItemNumber: 1)
        let secondItem = textList.marker(forItemNumber: 2)
        if (firstItem == secondItem) {
            return firstItem
        }

        let thirdItem = textList.marker(forItemNumber: 3)
        return "\(firstItem) \(secondItem) \(thirdItem)"
    }

    private func updateListStylePopUpButton(with textLists: [NSTextList]?) {
        let multipleItem = self.listStylePopUpButton.menu?.item(withTag: SpecialListItemTags.multiple.rawValue)
        multipleItem?.isHidden = true

        let customValueItem = self.listStylePopUpButton.menu?.item(withTag: SpecialListItemTags.customValue.rawValue)
        customValueItem?.isHidden = true

        guard let styles = textLists else {
            multipleItem?.isHidden = false
            self.listStylePopUpButton.selectItem(withTag: SpecialListItemTags.multiple.rawValue)
            return
        }

        guard let lastTextList = styles.last else {
            self.listStylePopUpButton.selectItem(withTag: SpecialListItemTags.none.rawValue)
            return
        }

        let indexOfItem = self.listStylePopUpButton.indexOfItem(withRepresentedObject: lastTextList.markerFormat.rawValue)
        if indexOfItem == -1 {
            customValueItem?.isHidden = false
            customValueItem?.title = self.popUpTitle(for: lastTextList)
            customValueItem?.representedObject = lastTextList.markerFormat.rawValue
            self.listStylePopUpButton.selectItem(withTag: SpecialListItemTags.customValue.rawValue)
        } else {
            self.listStylePopUpButton.selectItem(at: indexOfItem)
        }
    }

    @IBAction func listStyleChanged(_ sender: NSPopUpButton?) {
        guard let item = sender?.selectedItem else {
            return
        }

        if let specialItem = SpecialListItemTags(rawValue: item.tag) {
            if (specialItem == .multiple) {
                return
            }
            if (specialItem == .none) {
                self.typedViewModel.updateListType(to: nil)
                return
            }
            if (specialItem == .customise) {
                self.typedViewModel.editor?.showCustomListPanel()
                return
            }
        }

        guard let style = item.representedObject as? String else {
            return
        }

        let markerFormat = NSTextList.MarkerFormat(rawValue: style)
        let textList = NSTextList(markerFormat: markerFormat, options: 0)
        self.typedViewModel.updateListType(to: textList)
    }
}


extension TextEditorParagraphInspectorViewController: TextEditorParagraphInspectorView {
}
