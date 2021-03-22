//
//  CoppiceDocumentController.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CoppiceDocumentController: NSDocumentController {
    override func willPresentError(_ error: Error) -> Error {
        return error
    }
}
