//
//  ModelPlist.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import M3Data

//TODO:
/*
 - Versioned plists (v2, v3)
 - Use plists for saving (plist type returns model types it supports)
 - Handle migration between plists
    - Show alert notifying of upgrade (allow to hide in future)
    - Migration = create canvas links for all canvas pages
 */

struct ModelPlist {
    let canvases: [ModelID: [String: Any]]
    let pages: [ModelID: [String: Any]]
    let canvasPages: [ModelID: [String: Any]]
    let folders: [ModelID: [String: Any]]
    let canvasLinks: [ModelID: [String: Any]]
    let settings: [String: Any]
    let version: Int

    init(plist: [String: Any]) throws {
        guard let canvasPlist = plist["canvases"] as? [[String: Any]] else {
            throw M3Data.ModelPlist.Errors.missingCollection("canvases")
        }
        guard let pagesPlist = plist["pages"] as? [[String: Any]] else {
            throw M3Data.ModelPlist.Errors.missingCollection("pages")
        }
        guard let canvasPagesPlist = plist["canvasPages"] as? [[String: Any]] else {
            throw M3Data.ModelPlist.Errors.missingCollection("canvasPages")
        }
        guard let foldersPlist = plist["folders"] as? [[String: Any]] else {
            throw M3Data.ModelPlist.Errors.missingCollection("folders")
        }
        guard let canvasLinksPlist = plist["canvasLinks"] as? [[String: Any]] else {
            throw M3Data.ModelPlist.Errors.missingCollection("canvasLinks")
        }

        self.canvases = try ModelPlist.mapToModelIDKeys(canvasPlist)
        self.pages = try ModelPlist.mapToModelIDKeys(pagesPlist)
        self.canvasPages = try ModelPlist.mapToModelIDKeys(canvasPagesPlist)
        self.folders = try ModelPlist.mapToModelIDKeys(foldersPlist)
        self.canvasLinks = try ModelPlist.mapToModelIDKeys(canvasLinksPlist)

        self.settings = (plist["settings"] as? [String: Any]) ?? [:]

        self.version = (plist["version"] as? Int) ?? 1
    }

    private static func mapToModelIDKeys(_ collection: [[String: Any]]) throws -> [ModelID: [String: Any]] {
        var newCollection = [ModelID: [String: Any]]()
        for plistItem in collection {
            guard let idString = plistItem["id"] as? String, let id = ModelID(string: idString) else {
//                throw ModelReader.Errors.missingID(plistItem)
                return [:]
            }
            newCollection[id] = plistItem
        }
        return newCollection
    }
}
