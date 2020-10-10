//
//  PageContentEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol PageContentEditor: Editor {
    func startEditing(at point: CGPoint)
    func stopEditing()
    func isLink(at point: CGPoint) -> Bool
    func openLink(at point: CGPoint)

    var simulateInCanvas: Bool { get set }
}

extension PageContentEditor {
    func isLink(at point: CGPoint) -> Bool {
        return false
    }

    func openLink(at point: CGPoint) {}
}
