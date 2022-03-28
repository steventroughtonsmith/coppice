//
//  FolderContainable.swift
//  Coppice
//
//  Created by Martin Pilkington on 09/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import M3Data

/// An object that can be contained in a folder
public protocol FolderContainable: ModelObject {
    var containingFolder: Folder? { get set }
    var dateCreated: Date { get }
    var dateModified: Date { get }
    var title: String { get }
    var sortType: String { get }

    func removeFromContainingFolder()
}

extension FolderContainable {
    public func removeFromContainingFolder() {
        self.containingFolder?.remove([self])
    }
}
