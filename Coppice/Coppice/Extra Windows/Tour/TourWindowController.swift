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
        TourGetStartedViewController(),
    ]

    override func windowDidLoad() {
        super.windowDidLoad()
        let welcome = self.tourPanels.first!
        welcome.view.frame = self.panelContainer.bounds
        self.contentViewController?.addChild(welcome)
        self.panelContainer.addSubview(welcome.view)
        NSApp.setAccessibilityApplicationFocusedUIElement(self.tourPanels.first!.titleLabel.cell)
        self.updateContinueButton()
    }

    @objc dynamic private var currentPanelIndex: Int = 0 {
        didSet {
            self.updateContinueButton()
        }
    }

    private var isLastPanel: Bool {
        return (self.currentPanelIndex == (self.tourPanels.count - 1))
    }

    @IBOutlet weak var continueButton: NSButton!
    func updateContinueButton() {
        let localizedTitle = self.isLastPanel ? NSLocalizedString("Get Started", comment: "Tour Get Started Button Title")
                                              : NSLocalizedString("Continue", comment: "Tour Continue Button Title")

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        self.continueButton.attributedTitle = NSAttributedString(string: localizedTitle, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph,
        ])
    }


    @IBOutlet weak var panelContainer: NSView!
    private var isAnimatingPanel = false
    @IBAction func continueClicked(_ sender: Any) {
        guard self.isLastPanel == false else {
            if (NSDocumentController.shared.documents.count == 0) {
                NSDocumentController.shared.newDocument(self)
            }
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

    @IBAction func back(_ sender: Any?) {
        guard self.isAnimatingPanel == false else {
            return
        }
        self.isAnimatingPanel = true
        let currentPanel = self.tourPanels[self.currentPanelIndex]
        guard let previousPanel = self.tourPanels[safe: self.currentPanelIndex - 1] else {
            return
        }

        previousPanel.view.frame = self.panelContainer.bounds
        previousPanel.view.frame.origin.x = -previousPanel.view.frame.width

        self.contentViewController?.addChild(previousPanel)
        self.panelContainer.addSubview(previousPanel.view)
        self.panelContainer.layoutSubtreeIfNeeded()

        NSView.animate(withDuration: 0.75, timingFunction: CAMediaTimingFunction(name: .easeInEaseOut)) {
            var currentPanelFrame = currentPanel.view.frame
            currentPanelFrame.origin.x = currentPanelFrame.width
            currentPanel.view.frame = currentPanelFrame

            previousPanel.view.animator().frame = self.panelContainer.bounds
        } completion: {
            currentPanel.removeFromParent()
            currentPanel.view.removeFromSuperview()
            self.currentPanelIndex -= 1
            self.continueButton.isEnabled = true

            self.perform(#selector(self.updateItem(to:)), with: previousPanel.titleLabel.cell, afterDelay: 0)

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
    @IBOutlet var backButton: NSButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.cell?.setAccessibilityIdentifier("TourPanelTitle")
        self.backButton?.cell?.setAccessibilityIdentifier("TourPanelBack")
    }
}
