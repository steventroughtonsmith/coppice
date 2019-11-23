//
//  TextEditorInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import AppKit
import Combine


class TextEditorInspectorViewModel: BaseInspectorViewModel {
    let editor: InspectableTextEditor
    let modelController: ModelController
    init(editor: InspectableTextEditor, modelController: ModelController) {
        self.editor = editor
        self.modelController = modelController
        super.init()
        self.startObservingEditor()
    }

    override var title: String? {
        return NSLocalizedString("Text", comment: "Text editor inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.textEditor"
    }

    private var cachedAttributes: TextEditorAttributes? {
        didSet {
            self.keyPathsAffectedByAttributes.forEach {
                self.willChangeValue(forKey: $0)
                self.didChangeValue(forKey: $0)
                _ = self.textColours
            }
        }
    }


    //MARK: - Observation
    private var editorAttributesObserver: AnyCancellable?
    private func startObservingEditor() {
        self.editorAttributesObserver = self.editor.selectionAttributesDidChange.assign(to: \.cachedAttributes, on: self)
    }


    private var keyPathsAffectedByAttributes = [
        #keyPath(selectedFontFamily),
        #keyPath(selectedTypeface),
        #keyPath(fontSize),
        #keyPath(rawAlignment),
        #keyPath(textColour),
        #keyPath(isBold),
        #keyPath(isItalic),
        #keyPath(isUnderlined),
        #keyPath(isStruckthrough),
        #keyPath(textColours)
    ]


    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(typefaces)) {
            keyPaths.insert("selectedFontFamily")
        }

        return keyPaths
    }



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

    @objc dynamic var typefaceNames: [String] {
        return self.typefaces.map { $0.displayName }
    }

    @objc dynamic var textColours: TextColourList {
        let textColourList = TextColourList()
        guard let colourList = NSColorList(named: "Apple") else {
            return textColourList
        }

        colourList.allKeys.forEach {
            guard let colour = colourList.color(withKey: $0) else {
                return
            }
            textColourList.add(TextColour(name: $0, colour: colour))
        }

        textColourList.selectedColour = self.textColour
        return textColourList
    }

    @objc dynamic var selectedFontFamily: String? {
        get {
            self.cachedAttributes?.fontFamily
        }
        set {

        }
    }
    @objc dynamic var selectedTypeface: Typeface? {
        get {
            return self.typefaces.first { $0.fontName == self.cachedAttributes?.fontPostscriptName }
        }
        set {

        }
    }

    @objc dynamic var fontSize: NSNumber? {
        get {
            guard let fontSize = self.cachedAttributes?.fontSize else {
                return nil
            }
            return fontSize as NSNumber
        }
        set {

        }
    }

    @objc dynamic var rawAlignment: Int {
        get {
            return self.cachedAttributes?.alignment?.rawValue ?? -1
        }
        set {

        }
    }

    @objc dynamic var textColour: NSColor? {
        get { self.cachedAttributes?.textColour}
        set {}
    }

    @objc dynamic var isBold: Bool {
        get { self.cachedAttributes?.isBold ?? false }
        set {}
    }

    @objc dynamic var isItalic: Bool {
        get { self.cachedAttributes?.isItalic ?? false }
        set {}
    }

    @objc dynamic var isUnderlined: Bool {
        get { self.cachedAttributes?.isUnderlined ?? false }
        set {}
    }

    @objc dynamic var isStruckthrough: Bool {
        get { self.cachedAttributes?.isStruckthrough ?? false }
        set {}
    }
}
