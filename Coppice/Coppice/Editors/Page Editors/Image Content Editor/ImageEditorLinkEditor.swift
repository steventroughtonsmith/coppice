//
//  ImageEditorLinkEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import CoppiceCore
import Foundation

class ImageEditorLinkEditor: LinkEditor {
    @Published var selectedLink: LinkEditorValue = .noSelection
    var selectedLinkPublisher: Published<LinkEditorValue>.Publisher {
        return self.$selectedLink
    }

    func updateSelectedLink() {
        guard
            let selectedHotspots = self.viewModel?.hotspotCollection.selectedHotspots,
            selectedHotspots.isEmpty == false
        else {
            self.selectedLink = .noSelection
            return
        }

        let links = Set(selectedHotspots.compactMap(\.url))
        if links.count > 1 {
            self.selectedLink = .multipleSelection
        } else if let url = links.first {
            if let pageLink = PageLink(url: url) {
                self.selectedLink = .pageLink(pageLink)
            } else {
                self.selectedLink = .url(url)
            }
        } else {
            self.selectedLink = .empty
        }
    }

    func updateSelection(with link: LinkEditorValue) {
        guard
            let hotspotCollection = self.viewModel?.hotspotCollection,
            hotspotCollection.selectedHotspots.isEmpty == false
        else {
            return
        }

        switch link {
        case .noSelection, .multipleSelection:
            return
        case .empty:
            hotspotCollection.selectedHotspots.forEach { $0.url = nil }
        case .pageLink(let pageLink):
            hotspotCollection.selectedHotspots.forEach { $0.url = pageLink.url }
        case .url(let url):
            hotspotCollection.selectedHotspots.forEach { $0.url = url }
        }

        self.viewModel?.imageContent.hotspots = hotspotCollection.imageEditorHotspots.compactMap(\.imageHotspot)
    }

    weak var viewModel: ImageEditorViewModel?
}
