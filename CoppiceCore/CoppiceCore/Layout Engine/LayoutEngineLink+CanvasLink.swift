//
//  LayoutEngineLink+CanvasLink.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 08/08/2022.
//

import Foundation

extension LayoutEngineLink {
    public convenience init?(canvasLink: CanvasLink) {
        guard
            let sourcePage = canvasLink.sourcePage,
            let destinationPage = canvasLink.destinationPage,
            let pageLink = canvasLink.link
        else {
            return nil
        }
        self.init(id: canvasLink.id.uuid,
                  pageLink: pageLink,
                  sourcePageID: sourcePage.id.uuid,
                  destinationPageID: destinationPage.id.uuid)
    }
}
