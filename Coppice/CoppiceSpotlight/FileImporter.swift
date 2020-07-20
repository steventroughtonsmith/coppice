//
//  FileImporter.swift
//  CoppiceSpotlight
//
//  Created by Martin Pilkington on 20/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

@objc class FileImporter: NSObject {
    @objc static func importFile(at path: String, attributes: NSMutableDictionary) -> Bool {
        guard
            let fileWrapper = try? FileWrapper(url: URL(fileURLWithPath: path), options: []),
            let plistData = fileWrapper.fileWrappers?["data.plist"]?.regularFileContents,
            let plistDict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
        else {
            return false
        }

        guard
            let canvases = plistDict["canvases"] as? [[String: Any]],
            let pages = plistDict["pages"] as? [[String: Any]]
        else {
            return false
        }

        attributes[kMDItemNumberOfPages as Any] = pages.count
        attributes["com_mcubedsw_Coppice_pageTitles"] = pages.compactMap { $0["title"] }
        attributes["com_mcubedsw_Coppice_numberOfCanvases"] = canvases.count
        attributes["com_mcubedsw_Coppice_canvasTitles"] = canvases.compactMap { $0["title"] }
        return true
    }
}
