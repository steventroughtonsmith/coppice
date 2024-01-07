//
//  TestData.ModelController.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 01/08/2022.
//

import Cocoa

import CoppiceCore

extension TestData {
    class Model: TestData {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        override init() {
            super.init()
            self.modelController.settings.set("66FBC053-53A2-412D-918F-52C088E2F492", for: .documentIdentifier)
            self.modelController.settings.set(true, for: .pageGroupExpanded)
            self.modelController.settings.set(self.folderIDs[0].uuidString, for: .rootFolder)

            _ = self.pages
            _ = self.canvases
            _ = self.canvasPages
            _ = self.canvasLinks
            _ = self.folders
        }

        lazy var pages: [Page] = {
            return [
                self.modelController.pageCollection.newObject(modelID: Page.modelID(with: self.pageIDs[0])) {
                    $0.title = "Page 1"
                    $0.dateCreated = Date(timeIntervalSinceReferenceDate: 123)
                    $0.dateModified = Date(timeIntervalSinceReferenceDate: 456)
                    let content = Page.Content.Text()
                    content.text = NSAttributedString(string: "Foo Bar")
                    $0.content = content
                },
                self.modelController.pageCollection.newObject(modelID: Page.modelID(with: self.pageIDs[1])) {
                    $0.title = "Page 2"
                    $0.dateCreated = Date(timeIntervalSinceReferenceDate: 0)
                    $0.dateModified = Date(timeIntervalSinceReferenceDate: 0)
                    $0.contentSize = CGSize(width: 1024, height: 768)
                    $0.content = Page.Content.Text()
                },
                self.modelController.pageCollection.newObject(modelID: Page.modelID(with: self.pageIDs[2])) {
                    $0.title = "Page 3"
                    $0.dateCreated = Date(timeIntervalSinceReferenceDate: 999)
                    $0.dateModified = Date(timeIntervalSinceReferenceDate: 9999)
                    let content = Page.Content.Image()
                    content.setImage(NSImage(named: NSImage.applicationIconName)!, operation: .replace)
                    content.imageDescription = "This is an image"
                    $0.content = content
                },
            ]
        }()

        lazy var canvases: [Canvas] = {
            return [
                self.modelController.canvasCollection.newObject(modelID: Canvas.modelID(with: self.canvasIDs[0])) {
                    $0.title = "Canvas 1"
                    $0.sortIndex = 2
                    $0.theme = .auto
                    $0.viewPort = CGRect(x: 10, y: 20, width: 30, height: 40)
                    $0.dateCreated = Date(timeIntervalSinceReferenceDate: 30)
                    $0.dateModified = Date(timeIntervalSinceReferenceDate: 300)
                },
                self.modelController.canvasCollection.newObject(modelID: Canvas.modelID(with: self.canvasIDs[1])) {
                    $0.title = "Canvas 2"
                    $0.dateCreated = Date(timeIntervalSinceReferenceDate: 42)
                    $0.dateModified = Date(timeIntervalSinceReferenceDate: 42)
                    $0.sortIndex = 1
                    $0.theme = .light
                    $0.alwaysShowPageTitles = true
                    $0.zoomFactor = 0.5
                },
            ]
        }()

        lazy var canvasPages: [CanvasPage] = {
            return [
                self.modelController.canvasPageCollection.newObject(modelID: CanvasPage.modelID(with: self.canvasPageIDs[0])) {
                    $0.frame = CGRect(x: 0, y: 1, width: 2, height: 3)
                    $0.page = self.pages[0]
                    $0.canvas = self.canvases[0]
                    $0.zIndex = 0
                },
                self.modelController.canvasPageCollection.newObject(modelID: CanvasPage.modelID(with: self.canvasPageIDs[1])) {
                    $0.frame = CGRect(x: 30, y: 50, width: 200, height: 400)
                    $0.page = self.pages[1]
                    $0.canvas = self.canvases[0]
                    $0.zIndex = 2
                },
                self.modelController.canvasPageCollection.newObject(modelID: CanvasPage.modelID(with: self.canvasPageIDs[2])) {
                    $0.frame = CGRect(x: -30, y: -2, width: 600, height: 40)
                    $0.page = self.pages[1]
                    $0.canvas = self.canvases[1]
                    $0.zIndex = 0
                },
                self.modelController.canvasPageCollection.newObject(modelID: CanvasPage.modelID(with: self.canvasPageIDs[3])) {
                    $0.frame = CGRect(x: 280, y: 50, width: 200, height: 400)
                    $0.page = self.pages[2]
                    $0.canvas = self.canvases[0]
                    $0.zIndex = 1
                },
            ]
        }()

        lazy var canvasLinks: [CanvasLink] = {
            return [
                self.modelController.canvasLinkCollection.newObject(modelID: CanvasLink.modelID(with: self.canvasLinkIDs[0])) {
                    $0.link = PageLink(destination: Page.modelID(with: self.pageIDs[1]), source: CanvasPage.modelID(with: self.canvasPageIDs[0]), autoGenerated: false)
                    $0.destinationPage = self.canvasPages[1]
                    $0.sourcePage = self.canvasPages[0]
                },
                self.modelController.canvasLinkCollection.newObject(modelID: CanvasLink.modelID(with: self.canvasLinkIDs[1])) {
                    $0.link = PageLink(destination: Page.modelID(with: self.pageIDs[2]), source: CanvasPage.modelID(with: self.canvasPageIDs[1]), autoGenerated: false)
                    $0.destinationPage = self.canvasPages[3]
                    $0.sourcePage = self.canvasPages[1]
                },
            ]
        }()

        lazy var folders: [Folder] = {
            let otherFolder = self.modelController.folderCollection.newObject(modelID: Folder.modelID(with: self.folderIDs[1])) {
                $0.title = "My New Folder"
                $0.dateCreated = Date(timeIntervalSinceReferenceDate: 9241)
                $0.folderContents = [
                    self.pages[1],
                ]
            }
            let rootFolder = self.modelController.folderCollection.newObject(modelID: Folder.modelID(with: self.folderIDs[0])) {
                $0.title = Folder.rootFolderTitle
                $0.dateCreated = Date(timeIntervalSinceReferenceDate: 1429)
                $0.folderContents = [
                    self.pages[0],
                    otherFolder,
                    self.pages[2],
                ]
            }
            return [rootFolder, otherFolder]
        }()
    }
}
