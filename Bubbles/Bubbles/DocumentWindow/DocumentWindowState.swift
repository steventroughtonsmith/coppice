//
//  DocumentWindowState.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class DocumentWindowState: NSObject {
    @objc dynamic var selectedSidebarObjectIDString: String?
    var mainEditor: Editor?
    var activeEditor: Editor?
}
