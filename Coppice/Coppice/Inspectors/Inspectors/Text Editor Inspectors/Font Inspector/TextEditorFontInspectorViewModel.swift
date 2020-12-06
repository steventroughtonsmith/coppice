//
//  TextEditorInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import AppKit
import Combine
import CoppiceCore

class TextEditorFontInspectorViewModel: BaseInspectorViewModel {
    weak var editor: InspectableTextEditor?
    let modelController: ModelController
    init(editor: InspectableTextEditor, modelController: ModelController) {
        self.editor = editor
        self.modelController = modelController
        super.init()
        self.startObservingEditor()
    }

    override var title: String? {
        return NSLocalizedString("Font", comment: "Text editor inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.textEditor"
    }

    private var cachedAttributes: TextEditorFontAttributes? {
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
        self.editorAttributesObserver = self.editor?.selectedFontAttributesDidChange.sink { [weak self] in self?.cachedAttributes = $0 }
    }


    private var keyPathsAffectedByAttributes = [
        #keyPath(selectedFontFamily),
        #keyPath(selectedTypeface),
        #keyPath(fontSize),
        #keyPath(textColour),
        #keyPath(isBold),
        #keyPath(isItalic),
        #keyPath(isUnderlined),
        #keyPath(isStruckthrough),
    ]


    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(typefaces)) {
            keyPaths.insert("selectedFontFamily")
        }

        return keyPaths
    }


    //MARK: - Populating UI
    @objc dynamic var fontFamilies: [String] {
        return NSFontManager.shared.availableFontFamilies
    }

    @objc dynamic var typefaces: [Typeface] {
        guard let selectedFontFamily = self.selectedFontFamily,
            let members = NSFontManager.shared.availableMembers(ofFontFamily: selectedFontFamily) else {
            return []
        }
        return members.compactMap { Typeface(memberInfo: $0) }.sorted { $0.weight < $1.weight }
    }


    //MARK: - Selection
    @objc dynamic var selectedFontFamily: String? {
        get { self.cachedAttributes?.fontFamily }
        set { self.editor?.updateSelection(with: TextEditorFontAttributes(fontFamily: newValue)) }
    }
    @objc dynamic var selectedTypeface: Typeface? {
        get { self.typefaces.first { $0.fontName == self.cachedAttributes?.fontPostscriptName } }
        set { self.editor?.updateSelection(with: TextEditorFontAttributes(fontPostscriptName: newValue?.fontName)) }
    }

    @objc dynamic var fontSize: NSNumber? {
        get {
            guard let fontSize = self.cachedAttributes?.fontSize else {
                return nil
            }
            return fontSize as NSNumber
        }
        set {
            if let fontSize = newValue?.floatValue {
                self.editor?.updateSelection(with: TextEditorFontAttributes(fontSize: CGFloat(fontSize)))
            }
        }
    }

    @objc dynamic var textColour: NSColor? {
        get { self.cachedAttributes?.textColour}
        set { self.editor?.updateSelection(with: TextEditorFontAttributes(textColour: newValue)) }
    }

    @objc dynamic var isBold: Bool {
        get { self.cachedAttributes?.isBold ?? false }
        set {self.editor?.updateSelection(with: TextEditorFontAttributes(isBold: newValue)) }
    }

    @objc dynamic var isItalic: Bool {
        get { self.cachedAttributes?.isItalic ?? false }
        set { self.editor?.updateSelection(with: TextEditorFontAttributes(isItalic: newValue)) }
    }

    @objc dynamic var isUnderlined: Bool {
        get { self.cachedAttributes?.isUnderlined ?? false }
        set { self.editor?.updateSelection(with: TextEditorFontAttributes(isUnderlined: newValue)) }
    }

    @objc dynamic var isStruckthrough: Bool {
        get { self.cachedAttributes?.isStruckthrough ?? false }
        set { self.editor?.updateSelection(with: TextEditorFontAttributes(isStruckthrough: newValue)) }
    }
}
