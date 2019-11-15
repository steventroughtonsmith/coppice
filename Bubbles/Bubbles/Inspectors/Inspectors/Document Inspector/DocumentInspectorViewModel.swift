//
//  DocumentInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol DocumentInspectorView: class {

}


class DocumentInspectorViewModel: NSObject {
    weak var view: DocumentInspectorView?

    let document: Document
    let modelController: ModelController
    init(document: Document, modelController: ModelController) {
        self.document = document
        self.modelController = modelController
        super.init()
    }
}
