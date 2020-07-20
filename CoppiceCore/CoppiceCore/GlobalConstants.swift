//
//  GlobalConstants.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 20/07/2020.
//

import AppKit

public struct GlobalConstants {
    public static let urlScheme = "coppice"

    public static let appErrorDomain = "com.mcubedsw.Coppices"

    public enum ErrorCodes: Int {
        case readingDocumentFailed = 1
        case documentTooNew = 2
    }

    public static let minimumPageSize = CGSize(width: 150, height: 100)
    public static let linkedPageOffset: CGFloat = 50.0

    public static let bottomBarHeight: CGFloat = 27.0

    public static let newWindowSize = CGSize(width: 900, height: 600)

    public static let textEditorInsets = NSEdgeInsets(top: 10, left: 5, bottom: 5, right: 5)

    public static var maxAutomaticTextSize: CGSize {
        return CGSize(width: Page.standardSize.width * 1.5, height: Page.standardSize.height * 3)
    }

    public static var maxAutomaticTextSizeIncludingInsets: CGSize {
        return self.maxAutomaticTextSize.plus(width: self.textEditorInsets.left + self.textEditorInsets.right + 10,
                                              height: self.textEditorInsets.top + self.textEditorInsets.bottom + 10)
    }

    public static var maxCanvasThumbnailSize = CGSize(width: 240, height: 120)
}

public extension NSImage.Name {
    //Sidebar
    static let sidebarCanvas = "Canvas"
    static let sidebarFolder = "Folder"
    static let textPage = "TextPage"
    static let imagePage = "ImagePage"
}

public struct Symbols {
    public struct Text {
        public static let bold = "bold"
        public static let italic = "italic"
        public static let strikethrough = "strikethrough"
        public static let alignCenter = "text.aligncenter"
        public static let alignLeft = "text.alignleft"
        public static let alignRight = "text.alignright"
        public static let textFormat = "textformat"
        public static let underline = "underline"
    }

    public struct Page {
        public static let text = "doc.text"
        public static let folder = "folder"
        public static let image = "photo"
    }

    public struct Toolbars {
        public static let chevron = "chevron.down"
        public static var action: String {
            if #available(OSX 10.16, *) {
                return "ellipsis.circle"
            }
            return "NSActionTemplate"
        }
        public static let link = "link"
        public static let plus = "plus"
        public static let newCanvas = "rectangle.badge.plus"
        public static let leftSidebar = "sidebar.left"
        public static let rightSidebar = "sidebar.right"
        public static let canvasListToggle = "rectangle.leftthird.inset.fill"
    }

    public static var closePage: String {
        if #available(OSX 10.16, *) {
            return "xmark.circle.fill"
        }
        return "NSStopProgressFreestandingTemplate";
    }
}
