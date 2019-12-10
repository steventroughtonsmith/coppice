//
//  DocumentWindowState.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol DocumentWindow: class {
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void)
}

class DocumentWindowViewModel: NSObject {
    weak var document: Document?
    weak var window: DocumentWindow?
    @Published var selectedSidebarObjectID: ModelID?
    @Published var currentInspectors: [Inspector] = []

    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
    }


    //MARK: - Model Helpers
    var pageCollection: ModelCollection<Page> {
        return self.modelController.collection(for: Page.self)
    }

    var canvasCollection: ModelCollection<Canvas> {
        return self.modelController.collection(for: Canvas.self)
    }

    var canvasPageCollection: ModelCollection<CanvasPage> {
        return self.modelController.collection(for: CanvasPage.self)
    }


    //MARK: - Creating Pages
    @discardableResult func createPage() -> Page {
        let page = self.pageCollection.newObject()
        guard let selectedObjectID = self.selectedSidebarObjectID, (selectedObjectID.modelType == Canvas.modelType) else {
            self.selectedSidebarObjectID = page.id
            return page
        }

        if let canvas = self.canvasCollection.objectWithID(selectedObjectID) {
            canvas.add(page)
        }
        return page
    }

    func createPages(fromFilesAtURLs fileURLs: [URL], addingTo canvas: Canvas? = nil, centredOn point: CGPoint? = nil) -> [Page] {
        self.modelController.pushChangeGroup()

        let newPages = fileURLs.compactMap { self.pageCollection.newPage(fromFileAt: $0) }
        if let canvas = canvas {
            newPages.forEach { canvas.add($0) }
        }

        self.modelController.popChangeGroup()

        return newPages
    }



    //MARK: - Deleting Pages
    func delete(_ page: Page) {
        guard let alert = alertForDeleting(page) else {
            self.actuallyDelete(page)
            return
        }

        self.window?.showAlert(alert, callback: { (index) in
            let (type, _) = alert.buttons[index]
            if (type == .confirm) {
                self.actuallyDelete(page)
            }
        })
    }

    private func alertForDeleting(_ page: Page) -> Alert? {
        let canvases = Set(page.canvases.compactMap { $0.canvas })
        guard canvases.count > 0 else {
            return nil
        }
        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString("Delete Page '%@'", comment: "Delete Page alert title"),
                                                              page.title)

        let localizedMessage: String
        if canvases.count == 1 {
            let messageFormat = NSLocalizedString("This page is on the canvas '%@'. Deleting it will also remove it and any linked pages from that canvas.",
                                                  comment: "Delete Page single canvas alert message")
            localizedMessage = String.localizedStringWithFormat(messageFormat, canvases.first!.title)
        } else {
            let messageFormat = NSLocalizedString("This page is on %d canvases. Deleting it will also remove it and any linked pages from those canvases.",
                                                  comment: "Delete Page multiple pages alert message")
            localizedMessage = String.localizedStringWithFormat(messageFormat, canvases.count)
        }
        return Alert(title: localizedTitle,
                     message: localizedMessage,
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func actuallyDelete(_ page: Page) {
        self.modelController.pushChangeGroup()
        page.canvases.forEach {
            self.canvasPageCollection.delete($0)
        }
        self.pageCollection.delete(page)
        self.modelController.popChangeGroup()

        if self.selectedSidebarObjectID == page.id {
            self.selectedSidebarObjectID = nil
        }
    }


    //MARK: - Adding Pages To Canvas
    func addPage(at link: PageLink, to canvas: Canvas, centredOn point: CGPoint? = nil) {
        guard let page = self.pageCollection.objectWithID(link.destination) else {
            return
        }

        var sourcePage: CanvasPage? = nil
        if let source = link.source {
            sourcePage = self.canvasPageCollection.objectWithID(source)
        }

        canvas.add(page, linkedFrom: sourcePage, centredOn: point)
    }


    //MARK: - Creating Canvases
    @discardableResult func createCanvas() -> Canvas {
        return self.modelController.collection(for: Canvas.self).newObject()
    }


    //MARK: - Deleting Canvas
    func delete(_ canvas: Canvas) {
        guard let alert = alertForDeleting(canvas) else {
            self.actuallyDelete(canvas)
            return
        }

        self.window?.showAlert(alert, callback: { (index) in
            let (type, _) = alert.buttons[index]
            if (type == .confirm) {
                self.actuallyDelete(canvas)
            }
        })
    }

    private func alertForDeleting(_ canvas: Canvas) -> Alert? {
        guard canvas.pages.count > 0 else {
            return nil
        }

        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString("Delete Canvas '%@'", comment: "Delete Canvas alert title"),
                                                              canvas.title)
        return Alert(title: localizedTitle,
                     message: NSLocalizedString("Are you sure you want to delete this canvas?", comment: "Delete canvas confirm message"),
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func actuallyDelete(_ canvas: Canvas) {
        self.modelController.pushChangeGroup()
        canvas.pages.forEach {
            self.canvasPageCollection.delete($0)
        }
        self.canvasCollection.delete(canvas)
        self.modelController.popChangeGroup()

        if self.selectedSidebarObjectID == canvas.id {
            self.selectedSidebarObjectID = nil
        }
    }


    //Removing page from canvas
    func remove(_ canvasPage: CanvasPage) {
        self.modelController.pushChangeGroup()
        self.closeChildren(of: canvasPage)
        canvasPage.canvas = nil
        self.canvasPageCollection.delete(canvasPage)
        self.modelController.popChangeGroup()
    }

    private func closeChildren(of canvasPage: CanvasPage) {
        for child in canvasPage.children {
            self.closeChildren(of: child)
            child.canvas = nil
            self.canvasPageCollection.delete(child)
        }
    }
}
