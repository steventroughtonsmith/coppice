//
//  Canvas.Thumbnail.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 02/01/2024.
//

import Foundation
import M3Data

public struct Thumbnail: PlistConvertable {
    public let data: Data
    public let canvasID: ModelID

    public init(data: Data, canvasID: ModelID) {
        self.data = data
        self.canvasID = canvasID
    }


    public func toPlistValue() throws -> PlistValue {
        return ModelFile(type: "thumbnail", filename: "\(self.canvasID.uuid.uuidString)-thumbnail.png", data: self.data, metadata: [:])
    }

    public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
        guard
            let modelFile: ModelFile = try .fromPlistValue(plistValue),
            let thumbnailComponents = modelFile.filename?.components(separatedBy: "-thumbnail"),
            thumbnailComponents.count == 2,
            let uuid = UUID(uuidString: thumbnailComponents[0]),
            let data = modelFile.data
        else {
            throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
        }
        return self.init(data: data, canvasID: Canvas.modelID(with: uuid))
    }
}
