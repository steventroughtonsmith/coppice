//
//  TourWindow.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class TourWindowController: NSWindowController {

    override var windowNibName: NSNib.Name? {
        return "TourWindow"
    }

    private var tourPanels: [TourPanelViewController] = [
        TourWelcomeViewController(),
        TourMovieViewController(tourIdentifier: "TourPages"),
        TourMovieViewController(tourIdentifier: "TourCanvases"),
        TourMovieViewController(tourIdentifier: "TourLinks"),
        TourMovieViewController(tourIdentifier: "TourBranches"),
        TourGetStartedViewController()
    ]

    override func windowDidLoad() {
        super.windowDidLoad()
        let welcome = self.tourPanels.first!
        welcome.view.frame = self.panelContainer.bounds
        self.contentViewController?.addChild(welcome)
        self.panelContainer.addSubview(welcome.view)
        NSApp.setAccessibilityApplicationFocusedUIElement(self.tourPanels.first!.titleLabel.cell)
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(continueButtonTitle)) {
            keyPaths.insert("currentPanelIndex")
        }
        return keyPaths
    }

    @objc dynamic private var currentPanelIndex: Int = 0

    private var isLastPanel: Bool {
        return (self.currentPanelIndex == (self.tourPanels.count - 1))
    }


    @objc dynamic var continueButtonTitle: String {
        if self.isLastPanel {
            return NSLocalizedString("Get Started", comment: "Tour Get Started Button Title")
        }
        return NSLocalizedString("Continue", comment: "Tour Continue Button Title")
    }
    
    @IBOutlet weak var continueButton: NSButton!
    @IBOutlet weak var panelContainer: NSView!
    private var isAnimatingPanel = false
    @IBAction func continueClicked(_ sender: Any) {
        guard self.isLastPanel == false else {
            self.close()
            return
        }
        self.animateToNextPanel()
    }

    private func animateToNextPanel() {
        guard self.isAnimatingPanel == false else {
            return
        }
        self.isAnimatingPanel = true
        let currentPanel = self.tourPanels[self.currentPanelIndex]
        guard let nextPanel = self.tourPanels[safe: self.currentPanelIndex + 1] else {
            return
        }

        nextPanel.view.frame = self.panelContainer.bounds
        nextPanel.view.frame.origin.x = nextPanel.view.frame.width

        self.contentViewController?.addChild(nextPanel)
        self.panelContainer.addSubview(nextPanel.view)
        self.panelContainer.layoutSubtreeIfNeeded()

        NSView.animate(withDuration: 0.75, timingFunction: CAMediaTimingFunction(name: .easeInEaseOut)) {
            var currentPanelFrame = currentPanel.view.frame
            currentPanelFrame.origin.x = -currentPanelFrame.width
            currentPanel.view.frame = currentPanelFrame

            nextPanel.view.animator().frame = self.panelContainer.bounds
        } completion: {
            currentPanel.removeFromParent()
            currentPanel.view.removeFromSuperview()
            self.currentPanelIndex += 1
            self.continueButton.isEnabled = true
            
            self.perform(#selector(self.updateItem(to:)), with: nextPanel.titleLabel.cell, afterDelay: 0)
            
            self.isAnimatingPanel = false
        }
    }
    
    @objc dynamic func updateItem(to item: Any) {
        NSApp.setAccessibilityApplicationFocusedUIElement(item)
        NSAccessibility.post(element: item, notification: .focusedUIElementChanged)
    }
}


class TourPanelViewController: NSViewController {
    @IBOutlet var titleLabel: NSTextField!
}
