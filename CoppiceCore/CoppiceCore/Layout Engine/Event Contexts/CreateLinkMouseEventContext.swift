//
//  CreateLinkMouseEventContext.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 19/09/2022.
//

import Foundation

class CreateLinkMouseEventContext: CanvasMouseEventContext {
    let page: LayoutEnginePage?
    init(page: LayoutEnginePage?) {
        self.page = page
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        guard let page = layout.item(atCanvasPoint: location) as? LayoutEnginePage, page == self.page else {
            layout.finishLinking(withDestination: nil)
            return
        }

        layout.finishLinking(withDestination: page)

        print("create link on page: \(page.id)")
    }
}
