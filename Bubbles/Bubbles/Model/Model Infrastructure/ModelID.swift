//
//  ModelID.swift
//  Bubbles
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

/// Used for determining model type
struct ModelType: RawRepresentable, Equatable, Hashable {
    typealias RawValue = String

    let rawValue: String
    init?(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
}


struct ModelID: Equatable, Hashable {
    let modelType: ModelType
    let uuid: UUID

    init(modelType: ModelType, uuid: UUID = UUID()) {
        self.modelType = modelType
        self.uuid = uuid
    }

    init?(modelType: ModelType, uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.init(modelType: modelType, uuid: uuid)
    }
}


//MARK: - Pasteboard Conversion
extension ModelID {
    private static let UUIDKey = "uuid"
    private static let modelTypeKey = "modelType"

    static let PasteboardType = NSPasteboard.PasteboardType("com.mcubedsw.bubbles.modelID")
    var pasteboardItem: NSPasteboardItem {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList([ModelID.UUIDKey: self.uuid.uuidString, ModelID.modelTypeKey: self.modelType.rawValue],
                                       forType: ModelID.PasteboardType)
        return pasteboardItem
    }

    init?(pasteboardItem: NSPasteboardItem) {
        guard pasteboardItem.types.contains(ModelID.PasteboardType),
            let propertyList = pasteboardItem.propertyList(forType: ModelID.PasteboardType) as? [String: String],
            let uuidString = propertyList[ModelID.UUIDKey],
            let modelTypeString = propertyList[ModelID.modelTypeKey],
            let modelType = ModelType(rawValue: modelTypeString) else {
                return nil
        }
        self.init(modelType: modelType, uuidString: uuidString)
    }
}


//MARK: - PlistConversion
extension ModelID {
    var stringRepresentation: String {
        return "\(self.modelType.rawValue)_\(self.uuid.uuidString)"
    }

    init?(string: String) {
        let components = string.split(separator: "_")
        guard components.count == 2,
            let modelType = ModelType(rawValue: String(components[0])) else {
            return nil
        }
        self.init(modelType: modelType, uuidString: String(components[1]))
    }
}
