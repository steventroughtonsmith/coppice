//
//  CoppiceProUpsell.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class CoppiceProUpsell {
    static let shared = CoppiceProUpsell()

    enum ProPopoverUserAction {
        case hover
        case click
    }

    func createProPopover(for feature: ProFeature, userAction: ProPopoverUserAction) -> NSPopover {
        let upsellVC = ProUpsellViewController()
        upsellVC.currentFeature = feature
        let popover = NSPopover()
        popover.contentViewController = upsellVC
        switch userAction {
        case .hover:
            popover.behavior = .applicationDefined
            upsellVC.showFindOutMore = false
        case .click:
            popover.behavior = .transient
            upsellVC.showFindOutMore = true
        }
        return popover
    }

    func showProPopover(for feature: ProFeature, from view: NSView, preferredEdge: NSRectEdge) {
        let popover = self.createProPopover(for: feature, userAction: .click)
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
    }

    lazy var proImage: NSImage = {
        let localizedPro = NSLocalizedString("PRO", comment: "Coppice Pro short name")
        let attributedPro = NSAttributedString(string: localizedPro, attributes: [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 11),
        ])

        let bounds = attributedPro.boundingRect(with: CGSize(width: 100, height: 100), options: .usesLineFragmentOrigin)

        let verticalPadding: CGFloat = 1
        let horizontalPadding: CGFloat = 8
        let imageSize = bounds.rounded().size.plus(width: horizontalPadding * 2, height: verticalPadding * 2)

        let image = NSImage(size: imageSize, flipped: false) { (rect) -> Bool in
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            NSColor(named: "CoppiceGreen")?.setFill()
            path.fill()


            attributedPro.draw(at: CGPoint(x: horizontalPadding, y: verticalPadding))

            return true
        }
        image.accessibilityDescription = localizedPro
        return image
    }()

    var proTooltip: String {
        return NSLocalizedString("This feature requires a Coppice Pro subscription", comment: "")
    }

    func openProPage() {
        NSWorkspace.shared.open(URL(string: "https://mcubedsw.com/coppice#pro")!)
    }
}
