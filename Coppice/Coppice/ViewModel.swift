//
//  ViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 09/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ViewModel: NSObject {
    let documentWindowViewModel: DocumentWindowViewModel
    init(documentWindowViewModel: DocumentWindowViewModel) {
        self.documentWindowViewModel = documentWindowViewModel
        super.init()
        self.setup()
    }

    var modelController: CoppiceModelController {
        return self.documentWindowViewModel.modelController
    }

    func setup() {}
}
