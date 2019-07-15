//
//  Document.swift
//  Bubbles
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let newWindowController = DocumentWindowController(windowNibName: "DocumentWindow")
        self.addWindowController(newWindowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }



    //MARK: - Base Actions
    @IBAction func newPage(_ sender: Any?) {
        Swift.print("New Page")
    }

    @IBAction func newCanvas(_ sender: Any?) {
        Swift.print("New Canvas")
    }

}

