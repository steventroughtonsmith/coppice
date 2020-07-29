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
        NSApp.setAccessibilityApplicationFocusedUIElement(self.tourPanels.first!.titleLabel)
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
    @IBAction func continueClicked(_ sender: Any) {
        guard self.isLastPanel == false else {
            self.close()
            return
        }
        self.animateToNextPanel()
    }

    private func animateToNextPanel() {
        let currentPanel = self.tourPanels[self.currentPanelIndex]
        guard
            let nextPanel = self.tourPanels[safe: self.currentPanelIndex + 1],
            let window = self.window
        else {
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
            NSAccessibility.post(element: window,
                                 notification: .layoutChanged,
                                 userInfo: [NSAccessibility.NotificationUserInfoKey.uiElements: nextPanel.view.accessibilityChildren() ?? []])
        }
    }
}

extension TourWindowController: NSPageControllerDelegate {
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let identifier = object as? String else {
            preconditionFailure()
        }
        return identifier
    }

//    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
//        return self.tourPanels[identifier] ?? NSViewController()
//    }
////
////    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
////        guard
////            let identifer = object as? String,
////            let viewController = self.tourPanels[identifer]
////        else {
////            return
////        }
////
////        NSAccessibility.post(element: viewController.view, notification: .layoutChanged, userInfo: [NSAccessibility.NotificationUserInfoKey.uiElements: viewController.view.accessibilityChildren() ?? []])
////    }
//
//    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
//        guard let viewController = pageController.selectedViewController as? TourPanelViewController else {
//            return
//        }
////        NSAccessibility.post(element: viewController.view, notification: .layoutChanged, userInfo: [NSAccessibility.NotificationUserInfoKey.uiElements: viewController.view.accessibilityChildren() ?? []])
//        NSApp.setAccessibilityApplicationFocusedUIElement(viewController.titleLabel)
//        NSAccessibility.post(element: viewController.titleLabel, notification: .focusedUIElementChanged)
//    }
}


class TourPanelViewController: NSViewController {
    @IBOutlet var titleLabel: NSTextField!
}
