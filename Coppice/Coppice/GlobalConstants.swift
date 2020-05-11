//
//  GlobalConstants.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

struct GlobalConstants {
    static let urlScheme = "coppice"

    static let appErrorDomain = "com.mcubedsw.Coppices"

    enum ErrorCodes: Int {
        case readingDocumentFailed = 1
    }

    static let minimumPageSize = CGSize(width: 150, height: 100)
    static let linkedPageOffset: CGFloat = 50.0

    static let bottomBarHeight: CGFloat = 27.0

    static let newWindowSize = CGSize(width: 900, height: 600)

    static let textEditorInsets = NSEdgeInsets(top: 10, left: 5, bottom: 5, right: 5)

    static var maxAutomaticTextSize: CGSize {
        return CGSize(width: Page.standardSize.width * 1.5, height: Page.standardSize.height * 3)
    }

    static var maxAutomaticTextSizeIncludingInsets: CGSize {
        return self.maxAutomaticTextSize.plus(width: self.textEditorInsets.left + self.textEditorInsets.right + 10,
                                              height: self.textEditorInsets.top + self.textEditorInsets.bottom + 10)
    }

    static var maxCanvasThumbnailSize = CGSize(width: 240, height: 120)
}

extension NSImage.Name {
    //Sidebar
    static let sidebarCanvas = "Canvas"
    static let sidebarFolder = "Folder"
    static let textPage = "TextPage"
    static let imagePage = "ImagePage"
}

