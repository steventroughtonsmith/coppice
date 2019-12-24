//
//  TextEditorInspectorViewController.swift
//  Bubbles
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
    
    @IBOutlet weak var colourPopUpButton: NSPopUpButton!
    @IBOutlet weak var styleControl: NSSegmentedControl!
    @IBOutlet weak var alignmentControl: NSSegmentedControl!

    var typedViewModel: TextEditorInspectorViewModel {
        return self.viewModel as! TextEditorInspectorViewModel
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupAlignmentControl()
        self.setupStyleControl()
        self.setupColourPopUpButton()
    }


    //MARK: - Colour Control
    private var textColoursObserver: AnyCancellable!
    private func setupColourPopUpButton() {
        guard let popUpButton = self.colourPopUpButton,
            let menu = popUpButton.menu else {
            return
        }
//        self.textColoursObserver = self.typedViewModel.publisher(for: \.textColours)
//            .map { $0.generateMenuItems() }
//            .sink {
//                let (menuItems, selectedItem) = $0
//                menu.items = menuItems
//                popUpButton.select(selectedItem)
//            }
    }

    @IBAction func colourPopUpButtonChanged(_ sender: Any) {
        guard let selectedItem = self.colourPopUpButton.selectedItem else {
            return
        }

        if selectedItem.tag == -1 {
            let panel = NSColorPanel.shared
            panel.setTarget(self)
            panel.setAction(#selector(colourPanelChanged(_:)))
            panel.makeKeyAndOrderFront(self)

        }
        else if let textColour = selectedItem.representedObject as? TextColour{
            self.typedViewModel.textColour = textColour.colour
        }
    }

    @objc dynamic func colourPanelChanged(_ sender: Any?) {
        self.typedViewModel.textColour = NSColorPanel.shared.color
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
//
//        self.alignmentObserver = self.typedViewModel.publisher(for: \.rawAlignment)
//                                                    .map {alignmentControl.segment(forTag: $0) }
//                                                    .assign(to: \.selectedSegment, on: alignmentControl)
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
//        self.boldObserver = self.typedViewModel.publisher(for: \.isBold)
//                                               .sink { styleControl?.setSelected($0, forSegment: 0) }
//        self.italicObserver = self.typedViewModel.publisher(for: \.isItalic)
//                                                 .sink { styleControl?.setSelected($0, forSegment: 1) }
//        self.underlineObserver = self.typedViewModel.publisher(for: \.isUnderlined)
//                                                    .sink { styleControl?.setSelected($0, forSegment: 2) }
//        self.strikethroughObserver = self.typedViewModel.publisher(for: \.isStruckthrough)
//                                                        .sink { styleControl?.setSelected($0, forSegment: 3) }
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
}


extension TextColourList {
    func generateMenuItems() -> ([NSMenuItem], selected: NSMenuItem?) {
        var menuItems = [NSMenuItem]()
        for textColour in self.colours {
            let item = NSMenuItem(title: textColour.name, action: nil, keyEquivalent: "")
            item.representedObject = textColour
            item.image = self.image(for: textColour.colour)
            menuItems.append(item)
        }
        menuItems.append(NSMenuItem.separator())

        let customMenuItem = NSMenuItem(title: NSLocalizedString("Custom", comment: "Custom colour item"),
                                        action: nil,
                                        keyEquivalent: "")
        customMenuItem.tag = -1

        var selectedItem: NSMenuItem? = nil
        if let selectedColour = self.selectedColour {
            let selected = TextColour(colour: selectedColour)
            if let existingItem = menuItems.first(where: { ($0.representedObject as? TextColour) == selected}) {
                selectedItem = existingItem
            } else {
                customMenuItem.representedObject = TextColour(name: "Custom", colour: selectedColour)
                customMenuItem.image = self.image(for: selectedColour)
                selectedItem = customMenuItem
            }
        }
        menuItems.append(customMenuItem)
        return (menuItems, selectedItem)
    }

    private func image(for colour: NSColor) -> NSImage {
        return NSImage.init(size: NSSize(width: 16, height: 16), flipped: false) { (rect) -> Bool in
            colour.set()
            rect.fill()

            let bezierPath = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
            NSColor.black.set()
            bezierPath.stroke()
            return true
        }
    }
}
