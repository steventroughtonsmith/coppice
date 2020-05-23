//
//  RootViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol SplitViewContainable {
    func createSplitViewItem() -> NSSplitViewItem
}
