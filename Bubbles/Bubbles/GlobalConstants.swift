//
//  GlobalConstants.swift
//  Bubbles
//
//  Created by Martin Pilkington on 14/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

struct GlobalConstants {
    static let urlScheme = "bubbles"

    static let appErrorDomain = "com.mcubedsw.Bubbles"

    enum ErrorCodes: Int {
        case readingDocumentFailed = 1
    }

    static let minimumPageSize = CGSize(width: 150, height: 100)
    static let linkedPageOffset: CGFloat = 50.0

    static let bottomBarHeight: CGFloat = 27.0

    static let newWindowSize = CGSize(width: 900, height: 600)
}

extension NSImage.Name {
    //Sidebar
    static let sidebarCanvas = "Canvas"
    static let sidebarFolder = "Folder"
    static let textPage = "TextPage"
    static let imagePage = "ImagePage"
}

