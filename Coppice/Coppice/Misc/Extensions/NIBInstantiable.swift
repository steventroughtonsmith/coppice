//
//  NIBInstantiable.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

protocol NIBInstantiable {
    static var nibName: String { get }
    static var nibBundle: Bundle? { get }
    static func createFromNIB() -> Self
}

extension NIBInstantiable {
    static var nibBundle: Bundle? {
        return nil
    }

    static func createFromNIB() -> Self {
        guard let nib = NSNib(nibNamed: self.nibName, bundle: self.nibBundle) else {
            preconditionFailure("NIB with name '\(self.nibName)' not found")
        }
        var topLevelObjects: NSArray? = nil
        guard nib.instantiate(withOwner: nil, topLevelObjects: &topLevelObjects) else {
            preconditionFailure("Could not instantiate NIB with name '\(self.nibName)'")
        }
        guard let object = topLevelObjects?.first(where: { $0 is Self }) as? Self else {
            preconditionFailure("NIB with name '\(self.nibName)' does not contain top level object of type: \(Self.self)")
        }
        return object
    }
}
