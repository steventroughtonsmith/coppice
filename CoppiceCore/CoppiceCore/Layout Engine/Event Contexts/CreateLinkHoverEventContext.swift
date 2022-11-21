//
//  CreateLinkHoverEventContext.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 19/09/2022.
//

import Foundation

class CreateLinkHoverEventContext: CanvasHoverEventContext {
    let page: LayoutEnginePage
    init(page: LayoutEnginePage) {
        self.page = page
    }

    private var currentTargetPage: LayoutEnginePage? {
        didSet {
            guard self.currentTargetPage != oldValue else {
                return
            }
            oldValue?.message = nil
            self.currentTargetPage?.message = LayoutEnginePage.Message(message: "Link to Page", color: .linkColor)
        }
    }

    private var currentLink: LayoutEngineLink?
    private var highlightedLink: LayoutEngineLink?

    func cursorMoved(to location: CGPoint, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {
        let pageUnderCursor = layout.item(atCanvasPoint: location) as? LayoutEnginePage

        if self.currentTargetPage != pageUnderCursor || self.currentLink == nil {
            if let oldLink = self.currentLink {
                layout.remove([oldLink])
            }

            let link: LayoutEngineLink
            if let pageUnderCursor, pageUnderCursor.id != self.page.id {
                self.currentTargetPage = pageUnderCursor

                //If a link already exists between pages we don't want to add a second one, just highlight it
                if let existingLink = layout.linkBetween(source: self.page, andDestination: pageUnderCursor) {
                    existingLink.highlighted = true
                    self.highlightedLink = existingLink
                    return
                }

                self.cleanUpHighlightedLink()

                link = LayoutEngineLink(id: UUID(),
                                        pageLink: nil,
                                        sourcePageID: self.page.id,
                                        destinationPageID: pageUnderCursor.id)
            } else {
                self.cleanUpHighlightedLink()
                link = self.cursorLink(in: layout)
                self.currentTargetPage = nil
            }
            layout.add([link])
            self.currentLink = link
        }

        let cursorPage = self.cursorPage(in: layout)
        cursorPage.contentFrame = CGRect(origin: location, size: CGSize(width: 3, height: 3))
        if let pageUnderCursor {
            layout.modified([cursorPage, pageUnderCursor])
        } else {
            layout.modified([cursorPage])
        }
    }

    private func cleanUpHighlightedLink() {
        if let highlightedLink = self.highlightedLink {
            highlightedLink.highlighted = false
            self.highlightedLink = nil
        }
    }

    func cleanUp(in layoutEngine: LayoutEngine) {
        if let currentLink = self.currentLink, currentLink.linkLayoutEngine != nil {
            layoutEngine.remove([currentLink])
        }
        self.currentTargetPage?.message = nil
        layoutEngine.cursorPage = nil
    }

    private func cursorPage(in layout: LayoutEngine) -> LayoutEnginePage {
        if let cursorPage = layout.cursorPage {
            return cursorPage
        }

        let cursorPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        layout.cursorPage = cursorPage
        return cursorPage
    }


    //MARK: - Links
    private var cursorLink: LayoutEngineLink?
    private func cursorLink(in layout: LayoutEngine) -> LayoutEngineLink {
        if let cursorLink {
            return cursorLink
        }

        let cursorLink = LayoutEngineLink(id: UUID(),
                                          pageLink: nil,
                                          sourcePageID: self.page.id,
                                          destinationPageID: self.cursorPage(in: layout).id)
        self.cursorLink = cursorLink
        return cursorLink
    }
}
