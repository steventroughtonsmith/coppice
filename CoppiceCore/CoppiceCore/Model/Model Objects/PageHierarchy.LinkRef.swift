//
//  PageHierarchy.LinkRef.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 02/01/2024.
//

import Foundation
import M3Data

extension PageHierarchy {
    public struct LinkRef: PlistConvertable {
        var sourceID: ModelID
        var destinationID: ModelID
        var link: PageLink

        init(sourceID: ModelID, destinationID: ModelID, link: PageLink) {
            self.sourceID = sourceID
            self.destinationID = destinationID
            self.link = link
        }

        public func toPlistValue() throws -> PlistValue {
            return [
                "sourceID": try self.sourceID.toPlistValue(),
                "destinationID": try self.destinationID.toPlistValue(),
                "link": try self.link.toPlistValue(),
            ] as PlistValue
        }

        public static func fromPlistValue(_ plistValue: PlistValue) throws -> LinkRef {
            guard
                let value = plistValue as? [String: PlistValue],
                let sourceID = value["sourceID"],
                let destinationID = value["destinationID"],
                let link = value["link"]
            else {
                throw PlistConvertableError.invalidConversion(fromPlistValue: plistValue, to: self)
            }
            return LinkRef(sourceID: try .fromPlistValue(sourceID),
                           destinationID: try .fromPlistValue(destinationID),
                           link: try .fromPlistValue(link))
        }
    }
}
