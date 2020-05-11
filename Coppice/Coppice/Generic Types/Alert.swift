//
//  Alert.swift
//  Bubbles
//
//  Created by Martin Pilkington on 07/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

struct Alert {
    enum ButtonType: Equatable {
        case confirm
        case cancel
        case other
    }
    let title: String
    let message: String
    let buttons: [(ButtonType, String)]

    init(title: String, message: String = "", confirmButtonTitle: String? = nil, otherButtons: [String] = []) {
        self.title = title
        self.message = message

        var buttons = [(ButtonType, String)]()
        if let title = confirmButtonTitle {
            buttons.append((.confirm, title))
            buttons.append((.cancel, NSLocalizedString("Cancel", comment: "Cancel button title")))
        } else {
            buttons.append((.confirm, NSLocalizedString("OK", comment: "OK button title")))
        }

        buttons.append(contentsOf: otherButtons.map { (.other, $0) })
        self.buttons = buttons
    }
}
