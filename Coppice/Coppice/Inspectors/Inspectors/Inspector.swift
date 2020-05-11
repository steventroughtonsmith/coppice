//
//  Inspector.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

enum InspectorRanking: Int {
    case canvas = 10
    case page = 20
    case canvasPage = 30
    case content = 40
}

protocol Inspector {
    var title: String? { get }
    var collapseIdentifier: String { get }

    var ranking: InspectorRanking { get }
}


extension Inspector where Self: NSViewController {
    var collapseIdentifier: String {
        return self.identifier?.rawValue ?? "inspector"
    }
}
