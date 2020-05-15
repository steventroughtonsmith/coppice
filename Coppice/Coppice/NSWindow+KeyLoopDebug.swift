//
//  NSWindow+KeyLoopDebug.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSWindow {
    @IBAction func showKeyLoop(_ sender: Any?) {
        var viewRects = [CGRect]()

        let initialFirstResponder = self.initialFirstResponder
        var handledViews = [NSView]()
        var currentKeyView: NSView? = initialFirstResponder
        var currentIndex = 0
        repeat {
            guard let view = currentKeyView else {
                break
            }
            viewRects.append(view.convert(view.bounds, to: nil))
            handledViews.append(view)
            currentKeyView = view.nextValidKeyView
            currentIndex += 1
        } while (currentKeyView != nil) && (handledViews.contains(currentKeyView!) == false)

        let newKeyLoopView = KeyLoopView(viewRects: viewRects)
        self.showKeyLoopView(newKeyLoopView)
    }


    private func showKeyLoopView(_ keyLoopView: KeyLoopView) {
        let keyLoopWindow = NSWindow(contentRect: self.frame, styleMask: .borderless, backing: .buffered, defer: false)
        keyLoopWindow.backgroundColor = .clear
        keyLoopWindow.isOpaque = false
        keyLoopWindow.isReleasedWhenClosed = false
        self.addChildWindow(keyLoopWindow, ordered: .above)
        keyLoopWindow.makeKeyAndOrderFront(self)

        keyLoopWindow.contentView = keyLoopView
        keyLoopView.frame = CGRect(origin: .zero, size: keyLoopWindow.frame.size)

        keyLoopView.startAnimating()
    }
}



class KeyLoopView: NSView {
    let viewRects: [CGRect]
    var currentIndex = 0 {
        didSet {
            if self.currentIndex >= self.viewRects.count {
                self.endAnimation()
                return
            }
            self.setNeedsDisplay(self.bounds)
        }
    }
    init(viewRects: [CGRect]) {
        self.viewRects = viewRects
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlAccentColor.withAlphaComponent(0.3).setFill()
        NSColor.controlAccentColor.setStroke()

        guard self.currentIndex < self.viewRects.count else {
            self.endAnimation()
            return
        }

        let rect = self.viewRects[self.currentIndex]
        let path = NSBezierPath(rect: rect)
        path.fill()
        path.stroke()
    }


    override func mouseUp(with event: NSEvent) {
        self.timer?.invalidate()
        self.removeFromSuperview()
    }

    private var timer: Timer?

    func startAnimating() {
        self.timer?.invalidate()

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] (timer) in
            self?.currentIndex += 1
        }
    }

    private func endAnimation() {
        self.timer?.invalidate()
        self.window?.close()
    }
}
