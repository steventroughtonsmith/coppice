//
//  LayoutEnginePage+CanvasPage.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 21/07/2020.
//

import Foundation

extension LayoutEnginePage {
    /// Maps the supplied `CanvasPage`s into `LayoutEnginePage`s, sorting out the parent-child hierarchy
    ///
    /// Note, only handles canvas pages passed in, any children that are not in the supplied directory are not added
    public static func pages(from canvasPages: [CanvasPage]) -> [LayoutEnginePage] {
        var layoutEnginePages = [UUID: LayoutEnginePage]()
        for canvasPage in canvasPages {
            layoutEnginePages[canvasPage.id.uuid] = LayoutEnginePage(canvasPage: canvasPage)
        }

        for canvasPage in canvasPages {
            guard let layoutPage = layoutEnginePages[canvasPage.id.uuid] else {
                continue
            }
            //TODO: Replace children
//            for child in canvasPage.children {
//                guard let childLayoutPage = layoutEnginePages[child.id.uuid] else {
//                    continue
//                }
//                layoutPage.addChild(childLayoutPage)
//            }
        }
        return Array(layoutEnginePages.values)
    }

    public convenience init(canvasPage: CanvasPage) {
        self.init(id: canvasPage.id.uuid,
                  contentFrame: canvasPage.frame,
                  maintainAspectRatio: canvasPage.maintainAspectRatio,
                  minimumContentSize: canvasPage.minimumContentSize,
                  zIndex: canvasPage.zIndex)
    }
}
