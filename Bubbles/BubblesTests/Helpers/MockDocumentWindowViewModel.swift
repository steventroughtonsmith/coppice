//
//  MockDocumentWindowViewModel.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 09/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
@testable import Bubbles

class MockWindow: DocumentWindow {
    func invalidateRestorableState() {
    }

    var suppliedAlert: Alert?
    var callback: ((Int) -> Void)?
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void) {
        self.suppliedAlert = alert
        self.callback = callback
    }
}

class MockDocumentWindowViewModel: DocumentWindowViewModel {
    var openPageAtLinkArguments: (PageLink, Canvas)?
    var openPageAtLinkReturn: [CanvasPage]?
    override func openPage(at link: PageLink, on canvas: Canvas) -> [CanvasPage] {
        self.openPageAtLinkArguments = (link, canvas)
        if let returnValue = openPageAtLinkReturn {
            return returnValue
        }
        return super.openPage(at: link, on: canvas)
    }

    var addPagesToCanvasArguments: ([Page], Canvas, CGPoint?)?
    var addPagesToCanvasReturn: [CanvasPage]?
    override func addPages(_ pages: [Page], to canvas: Canvas, centredOn point: CGPoint? = nil) -> [CanvasPage] {
        self.addPagesToCanvasArguments = (pages, canvas, point)
        if let returnValue = self.addPagesToCanvasReturn {
            return returnValue
        }
        return super.addPages(pages, to: canvas, centredOn: point)
    }

    var createPagesFromFilesAtURLsArguments: ([URL], Folder?, FolderContainable?, Canvas?, CGPoint?)?
    var createPagesFromFilesAtURLsReturn: [Page]?
    override func createPages(fromFilesAtURLs fileURLs: [URL], in folder: Folder? = nil, below item: FolderContainable? = nil, addingTo canvas: Canvas? = nil, centredOn point: CGPoint? = nil) -> [Page] {
        self.createPagesFromFilesAtURLsArguments = (fileURLs, folder, item, canvas, point)
        if let returnValue = self.createPagesFromFilesAtURLsReturn {
            return returnValue
        }
        return super.createPages(fromFilesAtURLs: fileURLs, in: folder, below: item, addingTo: canvas, centredOn: point)
    }


    var deleteCanvasArguments: (Canvas)?
    override func delete(_ canvas: Canvas) {
        self.deleteCanvasArguments = (canvas)
        super.delete(canvas)
    }
}
