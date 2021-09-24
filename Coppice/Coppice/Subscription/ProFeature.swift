//
//  ProFeature.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

enum ProFeature {
    case unlimitedCanvases
    case canvasAppearance
    case textAutoLinking
    case pageFolders
}

extension ProFeature {
    var title: String {
        switch self {
        case .unlimitedCanvases:    return NSLocalizedString("Unlimited Canvases", comment: "Unlimited Canvases upsell title")
        case .canvasAppearance:     return NSLocalizedString("Canvas Appearance", comment: "Canvas Apperance upsell title")
        case .textAutoLinking:      return NSLocalizedString("Automatic Page Linking", comment: "Automatic Page Linking upsell title")
        case .pageFolders:          return NSLocalizedString("Page Folders", comment: "Page Folders upsell title")
        }
    }

    var body: String {
        switch self {
        case .unlimitedCanvases:
            return NSLocalizedString("Unlocking Coppice Pro allows you create an unlimited number of Canvases in each document, letting you make sense your thoughts from many different angles.", comment: "Unlimited Canvases upsell body")
        case .canvasAppearance:
            return NSLocalizedString("Feel like changing things up? With Coppice Pro you gain more ways to customise your canvases, including selecting the Canvas theme", comment: "Canvas Themes upsell body")
        case .textAutoLinking:
            return NSLocalizedString("Thoughts and ideas don't live in isolation. Upgrade to Pro and Coppice can help you connect your thoughts by automatically linking pages for you.", comment: "Automatic Page Linking upsell body")
        case .pageFolders:
            return NSLocalizedString("Over time your documents will grow to contain many Pages. Coppice Pro can help you keep your sidebar organised by grouping pages into Folders.", comment: "Page Folders upsell body")
        }
    }
}
