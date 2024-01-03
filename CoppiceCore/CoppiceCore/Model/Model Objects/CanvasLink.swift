//
//  CanvasLink.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 16/07/2022.
//

import Foundation
import M3Data

@Model
final public class CanvasLink {
    //MARK: - Properties
    @Attribute public var link: PageLink?

    //MARK: - Relationships
    @Relationship(inverse: \CanvasPage.linksIn) public var destinationPage: CanvasPage?
    @Relationship(inverse: \CanvasPage.linksOut) public var sourcePage: CanvasPage?
    @Relationship(inverse: \Canvas.links) public var canvas: Canvas?
}

extension ModelCollection where ModelType == CanvasLink {
    public func canvasLink(with pageLink: PageLink) -> CanvasLink? {
        return self.all.first(where: { $0.link == pageLink })
    }
}
