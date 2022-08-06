//
//  V2Plist.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 31/07/2022.
//

import Cocoa

import CoppiceCore

extension TestData.Plist {
    class V2: TestData {
        lazy var plistCanvases: [[String: Any]] = [
            [
                "id": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation,
                "title": "Canvas 1",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
                "dateModified": Date(timeIntervalSinceReferenceDate: 300),
                "sortIndex": 2,
                "theme": "auto",
                "viewPort": NSStringFromRect(CGRect(x: 10, y: 20, width: 30, height: 40)),
                "alwaysShowPageTitles": 0,
                "closedPageHierarchies": [String: Any](),
                "zoomFactor": 1,
            ],
            [
                "id": Canvas.modelID(with: self.canvasIDs[1]).stringRepresentation,
                "title": "Canvas 2",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 42),
                "dateModified": Date(timeIntervalSinceReferenceDate: 42),
                "sortIndex": 1,
                "theme": "light",
                "alwaysShowPageTitles": 1,
                "closedPageHierarchies": [String: Any](),
                "zoomFactor": 1,
            ],
        ]

        lazy var plistPages: [[String: Any]] = [
            [
                "id": Page.modelID(with: self.pageIDs[0]).stringRepresentation,
                "title": "Page 1",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 123),
                "dateModified": Date(timeIntervalSinceReferenceDate: 456),
                "content": ["type": "text", "filename": "\(self.pageIDs[0].uuidString).rtf"],
            ],
            [
                "id": Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                "title": "Page 2",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 0),
                "dateModified": Date(timeIntervalSinceReferenceDate: 0),
                "userPreferredSize": NSStringFromSize(CGSize(width: 1024, height: 768)),
                "content": ["type": "text"],
            ],
            [
                "id": Page.modelID(with: self.pageIDs[2]).stringRepresentation,
                "title": "Page 3",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 999),
                "dateModified": Date(timeIntervalSinceReferenceDate: 9999),
                "content": ["type": "image", "filename": "\(self.pageIDs[2].uuidString).png", "metadata": ["description": "This is an image"]],
            ],
        ]

        lazy var plistCanvasPages: [[String: Any]] = [
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[0]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: 0, y: 1, width: 2, height: 3)),
                "page": Page.modelID(with: self.pageIDs[0]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation,
                "zIndex": 0,
            ],
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[1]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: 30, y: 50, width: 200, height: 400)),
                "page": Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation,
                "parent": CanvasPage.modelID(with: self.canvasPageIDs[0]).stringRepresentation,
                "zIndex": 2,
            ],
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[2]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: -30, y: -2, width: 600, height: 40)),
                "page": Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[1]).stringRepresentation,
                "zIndex": 0,
            ],
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[3]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: 280, y: 50, width: 200, height: 400)),
                "page": Page.modelID(with: self.pageIDs[2]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation,
                "parent": CanvasPage.modelID(with: self.canvasPageIDs[1]).stringRepresentation,
                "zIndex": 1,
            ],
        ]

        lazy var content: [String: Data] = [
            "\(self.pageIDs[0].uuidString).rtf": try! NSAttributedString(string: "Foo Bar").data(from: NSRange(location: 0, length: 7), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]),
            "\(self.pageIDs[2].uuidString).png": NSImage(named: "NSAddTemplate")!.pngData()!,
        ]

        lazy var plistFolders: [[String: Any]] = [
            [
                "id": Folder.modelID(with: self.folderIDs[0]).stringRepresentation,
                "title": Folder.rootFolderTitle,
                "dateCreated": Date(timeIntervalSinceReferenceDate: 1429),
                "contents": [
                    Page.modelID(with: self.pageIDs[0]).stringRepresentation,
                    Folder.modelID(with: self.folderIDs[1]).stringRepresentation,
                    Page.modelID(with: self.pageIDs[2]).stringRepresentation,
                ],
            ],
            [
                "id": Folder.modelID(with: self.folderIDs[1]).stringRepresentation,
                "title": "My New Folder",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 9241),
                "contents": [
                    Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                ],
            ],
        ]


        let documentID = UUID(uuidString: "66FBC053-53A2-412D-918F-52C088E2F492")!
        var plistSettings: [String: Any] {
            return ["documentID": self.documentID.uuidString, "pageGroupExpanded": true]
        }


        var plist: [String: Any] {
            return [
                "canvases": self.plistCanvases,
                "pages": self.plistPages,
                "canvasPages": self.plistCanvasPages,
                "folders": self.plistFolders,
                "settings": self.plistSettings,
                "version": 2,
            ]
        }
    }
}
