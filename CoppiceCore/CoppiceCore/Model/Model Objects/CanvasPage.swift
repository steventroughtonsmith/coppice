//
//  CanvasPage.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Data

@Model
final public class CanvasPage {
    //MARK: - Attributes
    @Attribute public var frame: CGRect = .zero
    @Attribute public var zIndex: Int = -1

    public var title: String {
        return self.page?.title ?? ""
    }

    public var displayTitle: String {
        guard self.title.count > 0 else {
            return Page.localizedDefaultTitle
        }
        return self.title
    }

    public var maintainAspectRatio: Bool {
        return self.page?.content.maintainAspectRatio ?? false
    }

    public var minimumContentSize: CGSize {
        return self.page?.content.minimumContentSize ?? Page.defaultMinimumContentSize
    }


    //MARK: - Relationships
    @Relationship(inverse: \Page.canvasPages) public var page: Page? {
        didSet {
            if let page = self.page, self.frame.size == .zero {
                self.frame.size = page.contentSize
            }
            //TODO: Update title
        }
    }

    @Relationship(inverse: \Canvas.pages) public var canvas: Canvas?

    public var linksOut: Set<CanvasLink> {
        self.relationship(for: \.sourcePage)
    }

    public var linksIn: Set<CanvasLink> {
        self.relationship(for: \.destinationPage)
    }

    public var children: Set<CanvasPage> {
        return Set(self.linksOut.compactMap(\.destinationPage))
    }

    public var parent: CanvasPage? {
        return self.linksIn.first?.sourcePage
    }


    //MARK: - Links
    public func doesLink(to canvasPage: CanvasPage) -> Bool {
        if canvasPage == self {
            return false
        }
        let pagesLinkedTo = self.linksOut.compactMap(\.destinationPage)
        if pagesLinkedTo.contains(canvasPage) {
            return true
        }
        for pageLinkedTo in pagesLinkedTo {
            if pageLinkedTo.doesLink(to: canvasPage) {
                return true
            }
        }
        return false
    }

    public func existingLinkedCanvasPage(for page: Page) -> CanvasPage? {
        if page == self.page {
            return self
        }
        return self.linksOut.first(where: { $0.link?.destination == page.id })?.destinationPage
    }


    //MARK: - Helpers
    func updatePageID(_ newID: ModelID?) {
        self._pageID = newID
    }

    func contentSizeDidChange(to newSize: CGSize, oldSize: CGSize?) {
        var newFrame = self.frame
        if let oldSize = oldSize, oldSize != .zero {
            let scaleFactor = self.frame.width / oldSize.width
            newFrame.size = newSize.multiplied(by: scaleFactor)
        } else {
            newFrame.size = newSize
        }

        self.frame = newFrame
    }
}
