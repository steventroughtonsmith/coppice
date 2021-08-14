//
//  LinkInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/06/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

import CoppiceCore

class LinkInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "LinkInspectorContentView"
    }

    override var ranking: InspectorRanking { return .link }

    var typedViewModel: LinkInspectorViewModel {
        return self.viewModel as! LinkInspectorViewModel
    }

    @IBOutlet var linkField: NSSearchField!


    //MARK: - Subscribers
    enum SubscriptionKeys {
        case textValue
        case icon
        case placeholderValue
        case linkFieldEnabled
    }

    private var subscribers: [SubscriptionKeys: AnyCancellable] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()


        guard
            let linkField = self.linkField,
            let searchFieldCell = (linkField.cell as? NSSearchFieldCell),
            let searchButtonCell = searchFieldCell.searchButtonCell
        else {
            return
        }

        self.subscribers[.textValue] = self.typedViewModel.$textValue.assign(to: \.stringValue, on: self.linkField)
        self.subscribers[.icon] = self.typedViewModel.$icon.sink(receiveValue: { image in
            searchFieldCell.resetSearchButtonCell()
            guard let image = image else {
                searchButtonCell.image = nil
                return
            }
            //NSSearchFieldCell doesn't listen to our y adjustedments so lets just adjust the image itself
            let adjustedImage = NSImage(size: CGSize(width: image.size.width, height: image.size.height + 2), flipped: false, drawingHandler: { rect in
                image.draw(at: CGPoint(x: 0, y: 0), from: .zero, operation: .sourceOver, fraction: 1)
                return true
            })
            adjustedImage.isTemplate = true
            searchButtonCell.image = adjustedImage
        })
        self.subscribers[.placeholderValue] = self.typedViewModel.$placeholderValue.compactMap { $0 }.assign(to: \.placeholderString, on: self.linkField)
        self.subscribers[.linkFieldEnabled] = self.typedViewModel.$linkFieldEnabled.assign(to: \.isEnabled, on: self.linkField)
    }

    //Editor connection
        //hasURLContainerSelected
        //selectedURL

    //Handle read states:
        //No selection
        //Selection but no URL
        //External URL
        //Page URL
        //Invalid URL

    //Editing
        //Type external URL
        //Type name
        //Show completions
        //Select completion
        //Create page
        //Clear
        //External URL edge case

    private var pageSelector: PageSelectorWindowController?
}

extension LinkInspectorViewController: NSSearchFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.typedViewModel.documentWindowViewModel) { page in
            print("page: \(page)")
        }
        self.pageSelector = PageSelectorWindowController(viewModel: viewModel)
        self.pageSelector?.show(from: self.linkField, preferredEdge: .minY)
    }

    func controlTextDidChange(_ obj: Notification) {
        self.pageSelector?.viewModel.searchTerm = self.linkField.stringValue
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        self.pageSelector?.close()
        self.pageSelector = nil
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let pageSelector = self.pageSelector else {
            return false
        }
        return pageSelector.viewController.control(control, textView: textView, doCommandBy: commandSelector)
    }
}
