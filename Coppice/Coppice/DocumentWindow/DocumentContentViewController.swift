//
//  DocumentContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class DocumentContentViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    var currentInfoAlert: InfoAlertViewController? {
        didSet {
            guard self.currentInfoAlert != oldValue else {
                return
            }

            if let newValue = self.currentInfoAlert {
                self.addChild(newValue)
                newValue.view.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(newValue.view)
                NSLayoutConstraint.activate([
                    self.view.centerXAnchor.constraint(equalTo: newValue.view.centerXAnchor),
                    self.view.bottomAnchor.constraint(equalTo: newValue.view.bottomAnchor, constant: 50),
                ])
                newValue.view.alphaValue = 0
            }

            NSView.animate(withDuration: 0.5) {
                self.currentInfoAlert?.view.alphaValue = 1
                oldValue?.view.alphaValue = 0
            } completion: {
                oldValue?.removeFromParent()
                oldValue?.view.removeFromSuperview()
            }
        }
    }
}
