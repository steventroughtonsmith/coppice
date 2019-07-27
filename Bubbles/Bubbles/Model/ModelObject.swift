//
//  ModelObject.swift
//  Bubbles
//
//  Created by Martin Pilkington on 26/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol ModelObject: class {
    var modelController: ModelController? { get set }
    var id: UUID { get set }
}
