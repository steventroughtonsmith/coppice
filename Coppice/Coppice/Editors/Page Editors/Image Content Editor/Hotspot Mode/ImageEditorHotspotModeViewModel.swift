//
//  ImageEditorHotspotModeViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/02/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Foundation

import CoppiceCore

class ImageEditorHotspotModeViewModel {
    let imageContent: ImagePageContent
    init(imageContent: ImagePageContent) {
        self.imageContent = imageContent
    }

    //TODO:
    //- Observe page content's hotspots for changes
    //- Generate ImageEditorHotspots
    //- Update page content's hotspots when layout changes
}

extension ImageEditorHotspotModeViewModel: ImageEditorHotspotLayoutEngineDelegate {
    func layoutDidChange(in layoutEngine: ImageEditorHotspotLayoutEngine) {

    }

    func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine) {

    }
}
