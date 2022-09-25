//
//  CanvasTextView.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let canvasTextViewDidBecomeFirstResponder = Notification.Name(rawValue: "M3CanvasTextViewDidBecomeFirstResponderNotification")
    static let canvasTextViewDidResignFirstResponder = Notification.Name(rawValue: "M3CanvasTextViewDidResignFirstResponderNotification")
}

class CanvasTextView: NSTextView {
    override func mouseMoved(with event: NSEvent) {
        guard let canvasView = self.canvasView else {
            super.mouseMoved(with: event)
            return
        }
        let location = canvasView.convert(event.locationInWindow, from: nil)
        let hitView = canvasView.hitTest(location)
        if (hitView == self) && (canvasView.draggingCursor == nil) {
            super.mouseMoved(with: event)
        }
    }

    override func becomeFirstResponder() -> Bool {
        self.flashIfTabFocus()

        let became = super.becomeFirstResponder()
        if (became) {
            NotificationCenter.default.post(name: .canvasTextViewDidBecomeFirstResponder, object: self)
        }
        return became
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if (resigned) {
            self.perform(#selector(self.postResignNotification), with: nil, afterDelay: 0)
        }
        return resigned
    }

    @objc dynamic func postResignNotification() {
        NotificationCenter.default.post(name: .canvasTextViewDidResignFirstResponder, object: self)
    }


    private func flashIfTabFocus() {
        guard let event = NSApp.currentEvent else {
            return
        }

        //Apparently calling .specialKey on non key events throws an exception
        guard (event.type == .keyUp) || (event.type == .keyDown) else {
            return
        }

        guard (event.specialKey == .tab) || (event.specialKey == .backTab) else {
            return
        }

        let view = NSView(frame: self.bounds)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        view.alphaValue = 0.6
        self.addSubview(view)

        NSView.animate(withDuration: 1.0, timingFunction: CAMediaTimingFunction(name: .easeOut), animations: {
            view.alphaValue = 0
        }, completion: {
            view.removeFromSuperview()
        })
    }

    override var frame: NSRect {
        get { super.frame }
        set {
            guard let scrollView = self.enclosingScrollView else {
                super.frame = newValue
                return
            }
            var newFrame = newValue
            newFrame.size.width = scrollView.contentSize.width - scrollView.contentInsets.left - scrollView.contentInsets.right
            super.frame = newFrame
        }
    }

    //MARK: - Highlighted characters
    var highlightedCharacterRanges: [NSRange] = [] {
        didSet {
            self.updateHighlightedCharacters()
        }
    }

    private var highlightedCharacterViews: [HighlightedCharacterView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            self.highlightedCharacterViews.forEach { self.addSubview($0) }
        }
    }

    private func updateHighlightedCharacters() {
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer,
            let textStorage = self.textStorage
        else {
            return
        }

        var newViews = [HighlightedCharacterView]()
        for range in self.highlightedCharacterRanges {
            let string = textStorage.attributedSubstring(from: range)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let view = HighlightedCharacterView()
            view.attributedString = string
            view.frame = boundingRect.insetBy(dx: -3, dy: 0)
            newViews.append(view)
        }
        self.highlightedCharacterViews = newViews
    }
}
