//
//  MockCoppiceModelController.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 27/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class MockCoppiceModelController: CoppiceModelController {
    //MARK: - Page
    let createPageOfTypeMock = MockDetails<(PageContentType, Folder, FolderContainable?, ((Page) -> Void)?), Page>()
    @discardableResult override func createPage(ofType contentType: PageContentType = .text, in parentFolder: Folder, below item: FolderContainable? = nil, setup: ((Page) -> Void)? = nil) -> Page {
        if let returnValue = self.createPageOfTypeMock.called(withArguments: (contentType, parentFolder, item, setup)) {
            return returnValue
        }
        return super.createPage(ofType: contentType, in: parentFolder, below: item, setup: setup)
    }

    let createPagesFromFilesMock = MockDetails<([URL], Folder, FolderContainable?, (([Page]) -> Void)?), [Page]>()
    @discardableResult override func createPages(fromFilesAt urls: [URL], in parentFolder: Folder, below item: FolderContainable? = nil, setup: (([Page]) -> Void)? = nil) -> [Page] {
        if let returnValue = self.createPagesFromFilesMock.called(withArguments: (urls, parentFolder, item, setup)) {
            return returnValue
        }
        return super.createPages(fromFilesAt: urls, in: parentFolder, below: item, setup: setup)
    }

    let deletePageMock = MockDetails<(Page), Void>()
    override func delete(_ page: Page) {
        self.deletePageMock.called(withArguments: (page))
        super.delete(page)
    }


    //MARK: - Folder
    let createFolderMock = MockDetails<(Folder, FolderContainable?, ((Folder) -> Void)?), Folder>()
    @discardableResult override func createFolder(in parentFolder: Folder, below item: FolderContainable? = nil, setup: ((Folder) -> Void)? = nil) -> Folder {
        if let returnValue = self.createFolderMock.called(withArguments: (parentFolder, item, setup)) {
            return returnValue
        }
        return super.createFolder(in: parentFolder, below: item, setup: setup)
    }

    let deleteFolderMock = MockDetails<(Folder), Void>()
    override func delete(_ folder: Folder) {
        self.deleteFolderMock.called(withArguments: folder)
        super.delete(folder)
    }

    let deleteFolderItemsMock = MockDetails<([FolderContainable]), Void>()
    override func delete(_ folderItems: [FolderContainable]) {
        self.deleteFolderItemsMock.called(withArguments: (folderItems))
        super.delete(folderItems)
    }


    //MARK: - Canvas
    let createCanvasMock = MockDetails<(((Canvas) -> Void)?), Canvas>()
    @discardableResult override func createCanvas(setup: ((Canvas) -> Void)? = nil) -> Canvas {
        if let returnValue = self.createCanvasMock.called(withArguments: (setup)) {
            return returnValue
        }
        return super.createCanvas(setup: setup)
    }

    let deleteCanvasMock = MockDetails<(Canvas), Void>()
    override func delete(_ canvas: Canvas) {
        self.deleteCanvasMock.called(withArguments: (canvas))
        super.delete(canvas)
    }


    //MARK: - Canavs Pages
    let openPageMock = MockDetails<(PageLink, Canvas), [CanvasPage]>()
    @discardableResult override func openPage(at link: PageLink, on canvas: Canvas) -> [CanvasPage] {
        if let returnValue = self.openPageMock.called(withArguments: (link, canvas)) {
            return returnValue
        }
        return super.openPage(at: link, on: canvas)
    }

    let closeCanvasPageMock = MockDetails<(CanvasPage), Void>()
    override func close(_ canvasPage: CanvasPage) {
        self.closeCanvasPageMock.called(withArguments: (canvasPage))
        super.close(canvasPage)
    }
}
