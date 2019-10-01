//
//  ModelChangeGroupHandler.swift
//  Bubbles
//
//  Created by Martin Pilkington on 01/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol ModelChangeGroupHandler {
    func pushChangeGroup()
    func popChangeGroup()
}
