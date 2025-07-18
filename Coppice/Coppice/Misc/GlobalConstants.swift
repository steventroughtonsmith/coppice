//
//  GlobalConstants.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

extension GlobalConstants {
    static let newWindowSize = CGSize(width: 900, height: 600)
}

extension NSColor {
    static let canvasBackgroundDark = NSColor(named: "CanvasBackgroundDark") ?? .clear
    static let canvasBackgroundLight = NSColor(named: "CanvasBackgroundLight") ?? .clear

    static let arrowDark = NSColor(named: "ArrowColourDark") ?? .white
    static let arrowLight = NSColor(named: "ArrowColourLight") ?? .black

    static let illustrationBackground = NSColor(named: "IllustrationBackground") ?? .white
    static let illustrationBorder = NSColor(named: "IllustrationBorder") ?? .gray
    static let illustrationSelectedBackground = NSColor(named: "IllustrationSelectedBackground") ?? .gray
    static let illustrationSelectedBorder = NSColor(named: "IllustrationSelectedBorder") ?? .black

    static let pageEditorBackground = NSColor(named: "PageEditorBackground") ?? .windowBackgroundColor
}

extension URL {
    static let termsAndConditions = URL(string: "https://mcubedsw.com/terms")!
    static let privacyPolicy = URL(string: "https://mcubedsw.com/privacy")!
    static let coppicePro = URL(string: "https://mcubedsw.com/coppice#pro")!
    static let mcubedAccount = URL(string: "https://mcubedsw.com/account")!
    static let releaseNotes = URL(string: "https://mcubedsw.com/coppice/release_notes")!
    static let socials = URL(string: "https://mastodon.social/@mcubedsw")!
    static let blog = URL(string: "https://mcubedsw.com/blog")!
}


enum SidebarSize: String, CaseIterable {
    case system
    case small
    case medium
    case large

    var localizedName: String {
        switch self {
        case .system:
            return NSLocalizedString("System Default", comment: "System Default sidebar size name")
        case .small:
            return NSLocalizedString("Small", comment: "Small sidebar size name")
        case .medium:
            return NSLocalizedString("Medium", comment: "Medium sidebar size name")
        case .large:
            return NSLocalizedString("Large", comment: "Large sidebar size name")
        }
    }
}
