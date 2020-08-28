//
//  ProFeatureCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ProFeatureCell: NSView, NIBInstantiable {
    static var nibName: String = "ProFeatureCell"

    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var bodyField: NSTextField!

}
