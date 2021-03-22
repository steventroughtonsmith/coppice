//
//  Document.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class Document: NSDocument {
    lazy var modelController: CoppiceModelController = {
        CoppiceModelController(undoManager: self.undoManager!)
    }()

    static let documentVersion = GlobalConstants.documentVersion

    override class var autosavesInPlace: Bool {
        return true
    }

    var isBrandNewDocument = true

    override func makeWindowControllers() {
        let documentViewModel = DocumentWindowViewModel(modelController: self.modelController)
        documentViewModel.document = self

        let newWindowController = DocumentWindowController(viewModel: documentViewModel)
        //Need to temporarily disable window cascading for anything but a brand new document (i.e. opened via File -> New Document)
        newWindowController.shouldCascadeWindows = self.isBrandNewDocument
        newWindowController.windowFrameAutosaveName = "DocumentWindow-\(self.modelController.identifier)"
        self.addWindowController(newWindowController)
        //We need to force the window to open before we re-enable cascading
        newWindowController.window?.makeKeyAndOrderFront(self)
        newWindowController.shouldCascadeWindows = true

        if (self.isBrandNewDocument) {
            documentViewModel.performNewDocumentSetup()
            newWindowController.performNewDocumentSetup()
        }
    }

    func selectFirstCanvas() {
        guard let windowController = self.windowControllers.first as? DocumentWindowController else {
            return
        }

        let documentViewModel = windowController.viewModel

        if let canvas = self.modelController.canvasCollection.sortedCanvases.first {
            documentViewModel.updateSelection([.canvas(canvas.id)])
        } else {
            documentViewModel.updateSelection([.canvases])
        }
    }

    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        let modelReader = ModelReader(modelController: self.modelController, documentVersion: Document.documentVersion)
        do {
            try modelReader.read(fileWrapper)
            self.isBrandNewDocument = false
        } catch ModelReader.Errors.versionTooNew {
            throw NSError(domain: GlobalConstants.appErrorDomain,
                          code: GlobalConstants.ErrorCodes.readingDocumentFailed.rawValue,
                          userInfo: [
                              NSLocalizedFailureReasonErrorKey: NSLocalizedString("This document was saved by a newer version of Coppice", comment: "Document version too new error reason"),
                              NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please download the latest version of Coppice to open this Document", comment: "Document version too new error recovery suggestion"),
                          ])
        } catch {
            throw NSError(domain: GlobalConstants.appErrorDomain,
                          code: GlobalConstants.ErrorCodes.readingDocumentFailed.rawValue,
                          userInfo: [NSLocalizedFailureReasonErrorKey: NSLocalizedString("The document appears to be corrupted. Please contact support for help.", comment: "Document opening failure")])
        }
    }

    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let modelWriter = ModelWriter(modelController: self.modelController, documentVersion: Document.documentVersion)
        return try modelWriter.generateFileWrapper()
    }

    override func close() {
        super.close()
    }


    //MARK: - URL handling
    func handle(_ url: URL) -> Bool {
        guard let pageLink = PageLink(url: url),
            let windowController = self.windowControllers.first as? DocumentWindowController
        else {
            return false
        }
        return windowController.viewModel.openPage(at: pageLink)
    }
}

