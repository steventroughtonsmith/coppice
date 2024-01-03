//
//  PageHierarchy.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 15/08/2022.
//

import Foundation
import M3Data

@Model
final public class PageHierarchy {
    //MARK: - Attributes
    @Attribute public var rootPageID: ModelID?
    @Attribute public var entryPoints: [EntryPoint] = []
    @Attribute public var pages: [PageRef] = []
    @Attribute public var links: [LinkRef] = []

    //MARK: - Relationships
    @Relationship(inverse: \Canvas.pageHierarchies) public var canvas: Canvas?
}
