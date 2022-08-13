//
//  Set+M3Extensions.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 08/08/2022.
//

import Foundation

extension Set {
    public func differencesFrom(_ otherSet: Set<Element>) -> (added: Set<Element>, removed: Set<Element>, unchanged: Set<Element>) {
        let added = otherSet.subtracting(self)
        let removed = self.subtracting(otherSet)
        let unchanged = otherSet.subtracting(added)
        return (added, removed, unchanged)
    }
}
