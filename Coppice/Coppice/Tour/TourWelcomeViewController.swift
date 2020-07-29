//
//  TourWelcomeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class TourWelcomeViewController: TourPanelViewController {
    @IBOutlet weak var tourInterfaceView: TourInterfaceView!

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "TourWelcomeView", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tourInterfaceView.delegate = self
        self.updateSecondaryLabel(nil)
    }

    @IBOutlet weak var secondaryLabel: NSTextField!

    private func updateSecondaryLabel(_ component: TourInterfaceComponentView?) {
        guard let component = component else {
            self.secondaryLabel.stringValue = NSLocalizedString("Hover over the image above to learn about Coppice's UI.", comment: "Tour Welcome panel secondary label")
            return
        }

        let attributedLabel = NSMutableAttributedString(string: "\(component.componentName): ", attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)])
        attributedLabel.append(NSAttributedString(string: component.componentDescription, attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]))

        self.secondaryLabel.attributedStringValue = attributedLabel
    }
}


extension TourWelcomeViewController: TourInterfaceViewDelegate {
    func hovered(over component: TourInterfaceComponentView?, in interfaceView: TourInterfaceView) {
        self.updateSecondaryLabel(component)
    }
}
