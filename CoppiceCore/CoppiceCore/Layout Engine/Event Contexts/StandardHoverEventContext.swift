//
//  StandardHoverEventContext.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 18/09/2022.
//

import Foundation

class StandardHoverEventContext: CanvasHoverEventContext {
    func cursorMoved(to location: CGPoint, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {
        let item = self.itemUnderMouse(at: location, in: layout)
        guard item != self.currentItemUnderMouse else {
            return
        }

        self.currentItemUnderMouse = item
        layout.pageUnderMouse = item.page
        self.updateHighlightedLinks(using: item, in: layout)
    }

    private var currentItemUnderMouse: HoverState = .nothing
    private func itemUnderMouse(at location: CGPoint, in layout: LayoutEngine) -> HoverState {
        let item = layout.item(atCanvasPoint: location)

        if let page = item as? LayoutEnginePage {
            if let url = page.view?.link(atContentPoint: page.convertPointToContentSpace(location)) {
                return .page(page, PageLink(url: url))
            }
            return .page(page, nil)
        }
        if let link = item as? LayoutEngineLink {
            return .link(link)
        }
        return .nothing
    }

    enum HoverState: Equatable {
        case nothing
        case page(LayoutEnginePage, PageLink?)
        case link(LayoutEngineLink)

        var page: LayoutEnginePage? {
            if case .page(let page, _) = self {
                return page
            }
            return nil
        }
    }


    //MARK: - Link Highlighting
    private var highlightedLinks: [LayoutEngineLink] = []
    private var highlightedPage: LayoutEnginePage?

    private func updateHighlightedLinks(using item: HoverState, in layout: LayoutEngine) {
        let highlightedLinks: [LayoutEngineLink]
        let highlightedPage: LayoutEnginePage?
        switch item {
        case .nothing, .page(_, nil):
            highlightedLinks = []
            highlightedPage = nil
        case .page(let page, let link):
            highlightedLinks = layout.links.filter { $0.sourcePageID == page.id && $0.pageLink?.destination == link?.destination }
            highlightedPage = page
        case .link(let link):
            highlightedLinks = [link]
            let page = layout.page(withID: link.sourcePageID)
            if let pageLink = link.pageLink {
                page?.view?.highlightLinks(matching: pageLink)
            }
            highlightedPage = page
        }

        if highlightedPage != self.highlightedPage {
            self.highlightedPage?.view?.unhighlightLinks()
            self.highlightedPage = highlightedPage
        }

        if highlightedLinks != self.highlightedLinks {
            self.highlightedLinks.forEach { $0.highlighted = false }
            highlightedLinks.forEach { $0.highlighted = true }
            self.highlightedLinks = highlightedLinks
            layout.linksChanged()
        }
    }

    func cleanUp(in layoutEngine: LayoutEngine) {}
}
