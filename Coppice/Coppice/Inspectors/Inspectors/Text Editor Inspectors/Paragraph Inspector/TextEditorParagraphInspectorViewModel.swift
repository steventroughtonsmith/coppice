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

    private var cachedAttributes: TextEditorParagraphAttributes? {
        didSet {
            self.keyPathsAffectedByAttributes.forEach {
                self.willChangeValue(forKey: $0)
                self.didChangeValue(forKey: $0)
            }
        }
    }


    //MARK: - Observation
    private var editorAttributesObserver: AnyCancellable?
    private func startObservingEditor() {
        self.editorAttributesObserver = self.editor?.selectedParagraphAttributesDidChange.sink { [weak self] in self?.cachedAttributes = $0 }
    }


    private var keyPathsAffectedByAttributes = [
        #keyPath(rawAlignment),
        #keyPath(paragraphSpacing),
        #keyPath(lineHeightMultiple)
    ]


    @objc dynamic var rawAlignment: Int {
        get { self.cachedAttributes?.alignment?.rawValue ?? -1 }
        set { self.editor?.updateSelection(with: TextEditorParagraphAttributes(alignment: NSTextAlignment(rawValue: newValue))) }
    }

    @objc dynamic var paragraphSpacing: NSNumber? {
        get {
            guard let spacing = self.cachedAttributes?.paragraphSpacing else {
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
            guard var multiple = self.cachedAttributes?.lineHeightMultiple else {
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
}
