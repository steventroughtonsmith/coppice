//
//  TourGetStartedViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class TourGetStartedViewController: TourPanelViewController {

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "TourGetStartedView", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let localizedTitle = NSLocalizedString("View Sample Document…", comment: "View sample document tour string")
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        self.viewDocumentButton.attributedTitle = NSAttributedString(string: localizedTitle, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ])
    }

    @IBOutlet var viewDocumentButton: NSButton!

}
