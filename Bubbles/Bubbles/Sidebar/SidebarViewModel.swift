//
//  SidebarViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

protocol SidebarView: class {
    func reloadSelection()
    func reloadCanvases()
    func reloadPages()
}

class SidebarViewModel: ViewModel {
    weak var view: SidebarView?

    let notificationCenter: NotificationCenter
    init(documentWindowViewModel: DocumentWindowViewModel, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter

        super.init(documentWindowViewModel: documentWindowViewModel)
    }

//
//    func addPages(atIndexes indexes: IndexSet, toCanvasAtindex canvasIndex: Int) {
//        guard let canvas = self.canvasItems[safe: canvasIndex]?.canvas else {
//            return
//        }
//
//        let pages = self.pageItems[indexes].map { $0.page }
//        self.documentWindowViewModel.addPages(pages, to: canvas)
//    }


    //MARK: - Pages




    //MARK: - Deleting
//    func deletePages(atIndexes indexes: IndexSet) {
//        for index in indexes {
//            guard (index >= 0) && (index < self.pageItems.count) else {
//                continue
//            }
//            let page = self.pageItems[index].page
//            self.documentWindowViewModel.delete(page)
//        }
//    }
//
//    func deletePage(atIndex index: Int) {
//        guard (index >= 0) && (index < self.pageItems.count) else {
//            return
//        }
//
//        let page = self.pageItems[index].page
//        self.documentWindowViewModel.delete(page)
//    }


    //MARK: - Adding Files
//    func addPages(fromFilesAtURLs fileURLs: [URL], toCanvasAtIndex canvasIndex: Int?) -> [Page] {
//        var canvas: Canvas?
//        if let index = canvasIndex {
//            canvas = self.canvasItems[index].canvas
//        }
//
//        return self.documentWindowViewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: canvas)
//    }


    //MARK: - Selection
}
