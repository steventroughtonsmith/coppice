//
//  TextEditorParagraphInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/12/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

protocol TextEditorParagraphInspectorView: class {
}

class TextEditorParagraphInspectorViewModel: BaseInspectorViewModel {
    weak var view: TextEditorParagraphInspectorView?

    weak var editor: InspectableTextEditor?
    let modelController: ModelController
    init(editor: InspectableTextEditor, modelController: ModelController) {
        self.editor = editor
        self.modelController = modelController
        super.init()
        self.startObservingEditor()
    }

    override var title: String? {
        return NSLocalizedString("Paragraph", comment: "Text editor paragraph inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.textEditorParagraph"
    }

    private var cachedParagraphAttributes: TextEditorParagraphAttributes? {
        didSet {
            self.keyPathsAffectedByParagraphAttributes.forEach {
                self.willChangeValue(forKey: $0)
                self.didChangeValue(forKey: $0)
            }
        }
    }

    private var cachedListTypes: [NSTextList]? {
        didSet {
            self.willChangeValue(for: \.listTypes)
            self.didChangeValue(for: \.listTypes)
        }
    }

    //MARK: - Observation
    private var paragraphAttributesObserver: AnyCancellable?
    private var listTypesObserver: AnyCancellable?
    private func startObservingEditor() {
        self.paragraphAttributesObserver = self.editor?.selectedParagraphAttributesDidChange.sink { [weak self] in self?.cachedParagraphAttributes = $0 }
        self.listTypesObserver = self.editor?.selectedListTypesDidChange.sink { [weak self] in self?.cachedListTypes = $0 }
    }

    private var keyPathsAffectedByParagraphAttributes = [
        #keyPath(rawAlignment),
        #keyPath(paragraphSpacing),
        #keyPath(lineHeightMultiple),
    ]


    //MARK: - Properties
    @objc dynamic var rawAlignment: Int {
        get { self.cachedParagraphAttributes?.alignment?.rawValue ?? -1 }
        set { self.editor?.updateSelection(with: TextEditorParagraphAttributes(alignment: NSTextAlignment(rawValue: newValue))) }
    }

    @objc dynamic var paragraphSpacing: NSNumber? {
        get {
            guard let spacing = self.cachedParagraphAttributes?.paragraphSpacing else {
                return nil
            }
            return spacing as NSNumber
        }
        set {
            if let spacing = newValue?.floatValue {
                self.editor?.updateSelection(with: TextEditorParagraphAttributes(paragraphSpacing: CGFloat(spacing)))
            }
        }
    }

    @objc dynamic var lineHeightMultiple: NSNumber? {
        get {
            guard var multiple = self.cachedParagraphAttributes?.lineHeightMultiple else {
                return nil
            }
            if (multiple == 0) {
                multiple = 1.0
            }
            return multiple as NSNumber
        }
        set {
            if let multiple = newValue?.floatValue {
                self.editor?.updateSelection(with: TextEditorParagraphAttributes(lineHeightMultiple: CGFloat(multiple)))
            }
        }
    }

    @objc dynamic var listTypes: [NSTextList]? {
        return self.cachedListTypes
    }

    func updateListType(to listType: NSTextList?) {
        self.editor?.updateSelection(withListType: listType)
    }
}
