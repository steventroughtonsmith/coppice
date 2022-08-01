//
//  PlistV2.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 31/07/2022.
//

import Foundation
import M3Data

extension Plist {
    class V2: ModelPlist {
        override class var version: Int {
            return 2
        }
        
        override class var supportedTypes: [M3Data.ModelPlist.PersistenceTypes] {
            return [
                PersistenceTypes(modelType: Page.modelType, persistenceName: "pages"),
                PersistenceTypes(modelType: Folder.modelType, persistenceName: "folders"),
                PersistenceTypes(modelType: Canvas.modelType, persistenceName: "canvases"),
                PersistenceTypes(modelType: CanvasPage.modelType, persistenceName: "canvasPages"),
            ]
        }
        
        override func migrateToNextVersion() throws -> [String : Any] {
            return [:]
        }
    }
}
