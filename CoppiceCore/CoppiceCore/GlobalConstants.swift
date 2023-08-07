//
//  GlobalConstants.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 20/07/2020.
//

import AppKit

public struct GlobalConstants {
    public static let urlScheme = "coppice"
    public static let activateHost = "activate"

    public static let appErrorDomain = "com.mcubedsw.Coppices"

    public enum ErrorCodes: Int {
        case readingDocumentFailed = 1
        case documentTooNew = 2
        case documentMigrationFailed = 3
    }

    public static let linkedPageOffset: CGFloat = 50.0

    public static let bottomBarHeight: CGFloat = 27.0

    public static func textEditorInsets(fullSize: Bool = false) -> NSEdgeInsets {
        if (fullSize) {
            return NSEdgeInsets(top: 40, left: 40, bottom: 5, right: 40)
        }
        return NSEdgeInsets(top: 10, left: 5, bottom: 5, right: 5)
    }

    public static var maxAutomaticTextSize: CGSize {
        return CGSize(width: Page.standardSize.width * 1.5, height: Page.standardSize.height * 3)
    }

    public static var maxAutomaticTextSizeIncludingInsets: CGSize {
        return self.maxAutomaticTextSize.plus(width: self.textEditorInsets().left + self.textEditorInsets().right + 10,
                                              height: self.textEditorInsets().top + self.textEditorInsets().bottom + 10)
    }

    public static var maxCanvasThumbnailSize = CGSize(width: 240, height: 120)

    public struct DocumentContents {
        public static var dataPlist = "data.plist"
        public static var contentFolder = "content"
    }
}

public struct Symbols {
    public struct Text {
        public static let bold = "bold"
        public static let italic = "italic"
        public static let strikethrough = "strikethrough"
        public static let textFormat = "textformat"
        public static let underline = "underline"
    }

    public enum Size {
        case small
        case regular
        case large

        var suffix: String {
            switch self {
            case .small:
                return "-Small"
            case .large:
                return "-Large"
            default:
                return ""
            }
        }
    }

    public struct Page {
        public static func text(_ size: Size) -> String {
            return "TextPage\(size.suffix)"
        }

        public static func image(_ size: Size) -> String {
            return "ImagePage\(size.suffix)"
        }
    }

    public struct Sidebar {
        public static func folder(_ size: Size) -> String {
            return "Folder\(size.suffix)"
        }

        public static func canvases(_ size: Size) -> String {
            return "Canvases\(size.suffix)"
        }
    }

    public struct Toolbars {
        public static let chevron = "chevron.down"
        public static var action: String {
            if #available(OSX 10.16, *) {
                return "ellipsis.circle"
            }
            return "NSActionTemplate"
        }

        public static let link = "LinkNew"
        public static let plus = "plus"
        public static var newCanvas: String {
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 10 {
                return "NewCanvas10"
            }
            return "NewCanvas"
        }

        public static var leftSidebar: String {
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 10 {
                return "ToggleSidebar10"
            }
            return "ToggleSidebar"
        }

        public static var rightSidebar: String {
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 10 {
                return "ToggleInspectors10"
            }
            return "ToggleInspectors"
        }

        public static let canvasListToggle = "ToggleCanvasList"
    }

    public static var closePage: String {
        if #available(OSX 10.16, *) {
            return "xmark.circle.fill"
        }
        return "NSStopProgressFreestandingTemplate"
    }
}

extension NSError {
    public struct Coppice {
        public struct Document {
            public static func documentTooNew() -> NSError {
                return NSError(domain: GlobalConstants.appErrorDomain,
                               code: GlobalConstants.ErrorCodes.documentTooNew.rawValue,
                               userInfo: [
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString("This document was saved by a newer version of Coppice", comment: "Document version too new error reason"),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please download the latest version of Coppice to open this Document", comment: "Document version too new error recovery suggestion"),
                               ])
            }

            public static func migrationFailed(baseError: NSError) -> NSError {
                return NSError(domain: GlobalConstants.appErrorDomain,
                               code: GlobalConstants.ErrorCodes.documentMigrationFailed.rawValue,
                               userInfo: [
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString("Migrating document to latest version failed", comment: "Document migration failed"),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Something went wrong migrating document to the latest version. If you keep getting problems please contact support for help.", comment: "Document migration failed description"),
                                   NSUnderlyingErrorKey: baseError,
                               ])
            }

            public static func readingFailed() -> NSError {
                return NSError(domain: GlobalConstants.appErrorDomain,
                               code: GlobalConstants.ErrorCodes.readingDocumentFailed.rawValue,
                               userInfo: [NSLocalizedFailureReasonErrorKey: NSLocalizedString("The document appears to be corrupted. Please contact support for help.", comment: "Document opening failure")])
            }
        }
    }
}
