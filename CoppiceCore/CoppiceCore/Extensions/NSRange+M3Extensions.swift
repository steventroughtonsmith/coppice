//
//  NSRange+M3Extensions.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 18/06/2021.
//

import Foundation

extension NSRange {
    public func contains(_ otherRange: NSRange) -> Bool {
        return (self.lowerBound <= otherRange.lowerBound) && (self.upperBound >= otherRange.upperBound)
    }
}
