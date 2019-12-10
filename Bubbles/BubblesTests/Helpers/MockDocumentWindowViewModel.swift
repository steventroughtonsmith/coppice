//
//  MockDocumentWindowViewModel.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 09/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
@testable import Bubbles

class MockWindow: DocumentWindow {
    var suppliedAlert: Alert?
    var callback: ((Int) -> Void)?
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void) {
        self.suppliedAlert = alert
        self.callback = callback
    }
}

class MockDocumentWindowViewModel: DocumentWindowViewModel {
    
}
