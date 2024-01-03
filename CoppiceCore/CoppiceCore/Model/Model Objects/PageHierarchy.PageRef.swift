//
//  PageHierarchy.PageRef.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 02/01/2024.
//

import Foundation
import M3Data

extension PageHierarchy {
    public struct PageRef: PlistConvertable {
        var canvasPageID: ModelID
        var pageID: ModelID
        /// Position relative to the hierarchy
        var relativeContentFrame: CGRect

        internal init(canvasPageID: ModelID, pageID: ModelID, relativeContentFrame: CGRect) {
            self.canvasPageID = canvasPageID
            self.pageID = pageID
            self.relativeContentFrame = relativeContentFrame
        }

        public func toPlistValue() throws -> PlistValue {
            return [
                "canvasPageID": try self.canvasPageID.toPlistValue(),
                "pageID": try self.pageID.toPlistValue(),
                "relativeContentFrame": try self.relativeContentFrame.toPlistValue(),
            ] as PlistValue
        }

        public static func fromPlistValue(_ plistValue: PlistValue) throws -> PageRef {
            guard
                let value = plistValue as? [String: PlistValue],
                let canvasPageID = value["canvasPageID"],
                let pageID = value["pageID"],
                let relativeContentFrame = value["relativeContentFrame"]
            else {
                throw PlistConvertableError.invalidConversionFromPlistValue
            }
            return PageRef(canvasPageID: try .fromPlistValue(canvasPageID),
                           pageID: try .fromPlistValue(pageID),
                           relativeContentFrame: try .fromPlistValue(relativeContentFrame))
        }
    }
}
