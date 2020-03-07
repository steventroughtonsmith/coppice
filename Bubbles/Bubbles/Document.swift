//
//  Document.swift
//  Bubbles
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    lazy var modelController: BubblesModelController = {
        BubblesModelController(undoManager: self.undoManager!)
    }()

    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let documentViewModel = DocumentWindowViewModel(modelController: self.modelController)
        documentViewModel.document = self
        let newWindowController = DocumentWindowController(viewModel: documentViewModel)
        self.addWindowController(newWindowController)
    }

    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        let modelReader = ModelReader(modelController: self.modelController)
        do {
            try modelReader.read(fileWrapper)
        } catch {
            throw NSError(domain: GlobalConstants.appErrorDomain,
                          code: GlobalConstants.ErrorCodes.readingDocumentFailed.rawValue,
                          userInfo: [NSLocalizedFailureReasonErrorKey: NSLocalizedString("The document appears to be corrupted. Please contact support for help.", comment: "Document opening failure")])
        }
    }

    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let modelWriter = ModelWriter(modelController: self.modelController)
        return try modelWriter.generateFileWrapper()
    }

    override func close() {
        super.close()
    }


    //MARK: - URL handling
    func handle(_ url: URL) -> Bool {
        guard let pageLink = PageLink(url: url),
            let windowController = self.windowControllers.first as? DocumentWindowController else {
            return false
        }
        return windowController.viewModel.handle(pageLink)
    }

}

