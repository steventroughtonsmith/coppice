//
//  TourWindow.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class TourWindowController: NSWindowController {

    @IBOutlet var pageController: NSPageController!
    override var windowNibName: NSNib.Name? {
        return "TourWindow"
    }

    private var tourPanels: [String: NSViewController] = [
        "Welcome": TourWelcomeViewController(),
        "Pages": TourMovieViewController(tourIdentifier: "TourPages"),
        "Canvases": TourMovieViewController(tourIdentifier: "TourCanvases"),
        "Links": TourMovieViewController(tourIdentifier: "TourLinks"),
        "Branches": TourMovieViewController(tourIdentifier: "TourBranches"),
        "GetStarted": TourGetStartedViewController()
    ]

    override func windowDidLoad() {
        super.windowDidLoad()
        self.pageController.arrangedObjects = ["Welcome", "Pages", "Canvases", "Links", "Branches", "GetStarted"]
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(continueButtonTitle)) {
            keyPaths.insert("pageController.selectedIndex")
        }
        return keyPaths
    }

    private var isLastPanel: Bool {
        return (self.pageController.selectedIndex == (self.tourPanels.count - 1))
    }

    @objc dynamic var continueButtonTitle: String {
        if self.isLastPanel {
            return NSLocalizedString("Get Started", comment: "Tour Get Started Button Title")
        }
        return NSLocalizedString("Continue", comment: "Tour Continue Button Title")
    }
    
    @IBAction func continueClicked(_ sender: Any) {
        guard self.isLastPanel == false else {
            self.close()
            return
        }
        self.pageController.navigateForward(sender)
    }
}

extension TourWindowController: NSPageControllerDelegate {
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let identifier = object as? String else {
            preconditionFailure()
        }
        return identifier
    }

    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        return self.tourPanels[identifier] ?? NSViewController()
    }
}
