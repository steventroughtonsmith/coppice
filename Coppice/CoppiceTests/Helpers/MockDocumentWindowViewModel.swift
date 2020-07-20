//
//  MockDocumentWindowViewModel.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
@testable import Coppice
@testable import CoppiceCore

class MockWindow: DocumentWindow {
    func invalidateRestorableState() {
    }

    var suppliedAlert: Alert?
    var callback: ((Int) -> Void)?
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void) {
        self.suppliedAlert = alert
        self.callback = callback
    }
}

class MockDocumentWindowViewModel: DocumentWindowViewModel {
    var deleteCanvasArguments: (Canvas)?
    override func delete(_ canvas: Canvas) {
        self.deleteCanvasArguments = (canvas)
        super.delete(canvas)
    }
}
