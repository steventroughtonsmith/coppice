//
//  GlobalConstants.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 20/07/2020.
//

import AppKit

struct GlobalConstants {
    static let urlScheme = "coppice"

    static let appErrorDomain = "com.mcubedsw.Coppices"

    enum ErrorCodes: Int {
        case readingDocumentFailed = 1
        case documentTooNew = 2
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

struct Symbols {
    struct Text {
        static let bold = "bold"
        static let italic = "italic"
        static let strikethrough = "strikethrough"
        static let alignCenter = "text.aligncenter"
        static let alignLeft = "text.alignleft"
        static let alignRight = "text.alignright"
        static let textFormat = "textformat"
        static let underline = "underline"
    }

    struct Page {
        static let text = "doc.text"
        static let folder = "folder"
        static let image = "photo"
    }

    struct Toolbars {
        static let chevron = "chevron.down"
        static var action: String {
            if #available(OSX 10.16, *) {
                return "ellipsis.circle"
            }
            return "NSActionTemplate"
        }
        static let link = "link"
        static let plus = "plus"
        static let newCanvas = "rectangle.badge.plus"
        static let leftSidebar = "sidebar.left"
        static let rightSidebar = "sidebar.right"
        static let canvasListToggle = "rectangle.leftthird.inset.fill"
    }

    static var closePage: String {
        if #available(OSX 10.16, *) {
            return "xmark.circle.fill"
        }
        return "NSStopProgressFreestandingTemplate";
    }
}
